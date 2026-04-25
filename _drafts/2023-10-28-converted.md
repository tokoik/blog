---
title: "RealSense (2) メッシュ化した点群を Forward Rendering で描いてみる"
date: 2023-10-28
categories: [Unity,RealSense]
published: true
---

## Forward Rendering にしてみる

Unity のレンダリングパイプラインは他のゲームエンジンと同様、Deferred Rendering (遅延レンダリング) が標準になっています。Deferred Rendering はディスプレイへの表示を行う通常のフレームバッファに図形を直接描かずに、一旦、画面に表示されないフレームバッファ、いわゆるオフスクリーンバッファに描いた後に、それを使って最終的なレンダリング結果を生成する手法です。このオフスクリーンバッファには通常のフレームバッファが備えるカラーとデプスの他に、用途に応じて様々な用途を組み合わせて格納できるようになっています。

## 近年のハイクォリティなゲームでは凝ったマテリアルやリアルな照明効果、あるいは複雑な映像効果を実現するのが当たり前になっています。それにはレンダリングの途中経過など、様々な要素を組み合わせる必要があります。そこで、あらかじめオフスクリーンバッファにそういう要素を別々にレンダリングしておき、事後処理により最終的なレンダリング結果を得るようにします。こうすれば高度な映像表現が行えるだけでなく、そういう手間をかけた表現が隠面消去処理によって消されて無駄になってしまうことを避けることができ、レンダリングのパフォーマンスの向上も見込めます。なお、このようなオフスクリーンバッファを G-バッファと言います。これは日本発の技術です<%=fn "Saito, Takafumi, and Tokiichiro Takahashi. "Comprehensible rendering of 3-D shapes." Proceedings of the 17th annual conference on Computer graphics and interactive techniques. 1990." %>。

## ![MRT を使った遅延レンダリング](/images/20231028_0.jpg)

## しかし点群の表示のように、レンダリングプリミティブ数が非常に多いにもかかわらず、それほど高度な映像効果が必要ない場合は、Deferred Rendering のオーバーヘッドが負担になります。その場合はグラフィックス API を使って直接通常のフレームバッファに描いたほうが良い場合もあります。それを Forward Rendering と言います。ちなみに、私は Forward Rendering という用語を初めて聞いた時は何か新しい技術課と思ったのですが、意味を知って「え、普通に API で直接描いているだけじゃん」と思いました。ゲームエンジンのパイプラインに組み込んだこと自体が新しかったのかもしれませんけど。

## スクリプトの修正

[前回]({{ site.baseurl }}{% post_url 2023-10-27-post %})、Game Object の <code>TriangleMesh</code> の Mesh Renderer に組み込んだスクリプト <code>TriangleMeshRenderer</code> を修正します。Mesh Renderer は G-バッファにレンダリングするために使うので、Forward Rendering では使用しません。したがって Mesh Renderer や Mesh Filter は不要なのですが、ここで削除すると手順が増えるので残しておきます。一方 Mesh は使わないので、<code>TriangleMeshRenderer</code> クラスからは削除します。代わりに、この Mesh に組み込んでいた頂点やインデックスのデータを保持する <code>GraphicsBuffer</code> のメンバ <code>vertexBuffer</code> と <code>indexBuffer</code> を追加します。また <code>Material</code> を保持するメンバ <code>material</code> も追加しておきます。

```cpp
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
// public class RsPointCloudRenderer : MonoBehaviour
public class TriangleMeshRenderer : MonoBehaviour
{
  public RsFrameProvider Source;
  //private Mesh mesh;
  private GraphicsBuffer vertexBuffer = null;
  private GraphicsBuffer indexBuffer = null;
  private Material material;
  private Texture2D uvmap;
 
```

## RealSense に対応したメッシュの出たを作成するメソッド <code>ResetMesh()</code> では、Mesh Renderer に組み込んでいた <code>Material</code> を、メンバ変数 <code>material</code> に保持するようにします。なお、Mesh Renderer を削除した場合は <code>Resources.Load()</code> を使って読み込む必要があります。

```cpp
  private void ResetMesh(int width, int height)
  {
    Assert.IsTrue(SystemInfo.SupportsTextureFormat(TextureFormat.RGFloat));
    uvmap = new Texture2D(width, height, TextureFormat.RGFloat, false, true)
    {
      wrapMode = TextureWrapMode.Clamp,
      filterMode = FilterMode.Point,
    };
    //GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_UVMap", uvmap);
    material = GetComponent<MeshRenderer>().sharedMaterial;
    material.SetTexture("_UVMap", uvmap);
```

## Mesh は使わないので、それに関連するコードは削除します。代わりに、頂点データを格納する <code>GraphicsBuffer</code> を <code>vertexBuffer</code> に確保します。また、それをシェーダに渡すために <code>material</code> にセットします。

```cpp
    //if (mesh != null)
    //  mesh.Clear();
    //else
    //  mesh = new Mesh()
    //  {
    //    indexFormat = IndexFormat.UInt32,
    //  };
 
    vertices = new Vector3[width * height];
    if (vertexBuffer != null)
      vertexBuffer.Release();
    vertexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured,
      vertices.Length, sizeof(float) * 3);
    material.SetBuffer("_Vertex", vertexBuffer);
```

## 同様にイデックスデータを格納する <code>GraphicsBuffer</code> を <code>indexBuffer</code> に確保します。

```cpp
    //var indices = new int[vertices.Length];
    //for (int i = 0; i < vertices.Length; i++)
    //  indices[i] = i;
    var indices = CreateTriangleMeshIndex(width - 1, height - 1);
    if (indexBuffer != null)
      indexBuffer.Release();
    indexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Index,
      indices.Length, sizeof(int));
    indexBuffer.SetData(indices);
```

## この後の Mesh に関連するコードは削除します。その結果、テクスチャ座標 UV を渡すことができなくなってしまいますが、これは後で何とかします。

```cpp
    //mesh.MarkDynamic();
    //mesh.vertices = vertices;
 
    //var uvs = new Vector2[width * height];
    //Array.Clear(uvs, 0, uvs.Length);
    //for (int j = 0; j < height; j++)
    //{
    //  for (int i = 0; i < width; i++)
    //  {
    //    uvs[i + j * width].x = i / (float)width;
    //    uvs[i + j * width].y = j / (float)height;
    //  }
    //}
 
    //mesh.uv = uvs;
 
    //mesh.SetIndices(indices, MeshTopology.Points, 0, false);
    //mesh.SetIndices(indices, MeshTopology.Triangles, 0, false);
    //mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 10f);
 
    //GetComponent<MeshFilter>().sharedMesh = mesh;
  }
```

<code>OnDestroy()</code> ではもともと Mesh が作られていたら <code>Dispose()</code> が呼ばれていたので、代わりに <code>vertexBuffer</code> が作られていたら、それを開放するついでに Game Object を <code>Dispose()</code> することにします。これでいいんでしょうか。

```cpp
  void OnDestroy()
  {
    if (q != null)
    {
      q.Dispose();
      q = null;
    }
 
    //if (mesh != null)
    //  Destroy(null);
    if (indexBuffer != null)
      indexBuffer.Release();
    if (vertexBuffer != null)
    {
      vertexBuffer.Release();
      Destroy(null);
    }
  }
```

## RealSense から頂点データを取り出して Mesh を更新していた <code>LastUpdate()</code> では、これまで <code>points</code> に取り出した頂点の数が Mesh の頂点の数と比較して違っていたら Mesh を作り直していました。Mesh を使わなくなったので、代わりにこれを (頂点データの一時保管に使う) <code>vertices</code> の長さと比較することにします。

```cpp
  protected void LateUpdate()
  {
    if (q != null)
    {
      Points points;
      if (q.PollForFrame<Points>(out points))
        using (points)
        {
          //if (points.Count != mesh.vertexCount)
          if (points.Count != vertices.Length)
          {
              using (var p = points.GetProfile<VideoStreamProfile>())
              ResetMesh(p.Width, p.Height);
          }
```

## そのあと <code>points</code> の頂点データを一時保管用の配列 <code>vertices</code> にコピーして Mesh に設定していましたが、これも Mesh の代わりに <code>GraphicsBuffer</code> の <code>vertexBuffer</code> に格納するようにします。本当は <code>uvmap</code> 同様 <code>points.VertexData</code> を直接 <code>vertexBuffer</code> にコピーしたかったんですけど、<code>points.VertexData</code> の先のデータを <code>vertexBuffer.GetNativeBufferPtr()</code> の先にコピーする方法がわかりませんでした (<code>Marshal.Copy()</code> を使う？)。

```cpp
          if (points.TextureData != IntPtr.Zero)
          {
            uvmap.LoadRawTextureData(points.TextureData, points.Count * sizeof(float) * 2);
            uvmap.Apply();
          }
 
          if (points.VertexData != IntPtr.Zero)
          {
            points.CopyVertices(vertices);
 
            //mesh.vertices = vertices;
            //mesh.UploadMeshData(false);
            vertexBuffer.SetData(vertices);
          }
        }
    }
  }
```

## 最後に <code>OnRenderObject()</code> メソッドを追加します。この Game Object <code>TriangleMesh</code> では Mesh Renderer では描画しませんから、<code>OnRenderObject()</code> で <code>Graphics.DrawProceduralNow()</code> により直接描画します。

```cpp
  void OnRenderObject()
  {
    if (indexBuffer != null)
    {
      material.SetPass(0);
      Graphics.DrawProceduralNow(MeshTopology.Triangles, indexBuffer, indexBuffer.count);
    }
  }
}
```

## シェーダの修正

というわけで Mesh Renderer を使わず Mesh を削除してしまったので、テクスチャ座標 UV を渡していません。これを「後で何とかします」ということで、シェーダで何とかすることにします。マテリアルの <code>TriangleMeshMat</code> に組み込んだシェーダの <code>TriangleMesh</code> を修正します。バーテックスシェーダ <code>vert()</code> に入力する頂点属性には位置 <code>POSITION</code> もテクスチャ座標 <code>TEXCOORD0</code> も存在しなくなったので、その構造体 <code>appdata</code> は削除してしまいます。

```cpp
Shader "Unlit/TriangleMesh" {
  Properties{
    _MainTex("Texture", 2D) = "white" {}
    _UVMap("UV", 2D) = "" {}
  }
 
  SubShader
  {
    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
 
      #include "UnityCG.cginc"
 
      //struct appdata
      //{
      //  float4 vertex : POSITION;
      //  float2 uv : TEXCOORD0;
      //};
 
      struct v2f
      {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
      };
```

## 代わりに「本当の」テクスチャ座標 UV が入っている <code>_UVMap</code> のテクスチャサイズ <code>_UVMap_TexelSize</code> と、<code>GraphicsBuffer</code> の <code>vertexBuffer</code> を受け取る <code>StructuredBuffer</code> の <code>_Vertex</code> を追加します。

```cpp
      sampler2D _MainTex;
      sampler2D _UVMap;
      float4 _UVMap_TexelSize;            // 追加
      StructuredBuffer<float3> _Vertex;  // 追加
 
```

## またバーテックスシェーダ <code>vert()</code> では頂点番号 <code>SV_VertexID</code> を <code>vertex_id</code> として受け取り、それを使って <code>_Vertex</code> から頂点の位置を取り出します。こういう風にしたのは、このあと Compute Shader を使ってごにょごにょしたいと思っていることもあるからですね。

```cpp
      //v2f vert(appdata v)
      v2f vert(uint vertex_id : SV_VertexID)
      {
        v2f v;
        v.vertex = float4(_Vertex[vertex_id], 1.0);
```

## そして <code>_UVMap</code> をサンプリングするためのテクスチャ座標 UV を <code>vertex_id</code> と <code>_UVMap_TexelSize</code> を使って求めます。

```cpp
        if (all((float3)v.vertex == 0.0))
        {
          v.vertex.w = 0.0;
          return v;
        }
 
        // UV を vertex_id から求める
        v.uv = float2(fmod(vertex_id, _UVMap_TexelSize.z) * _UVMap_TexelSize.x,
          floor(vertex_id * _UVMap_TexelSize.x) * _UVMap_TexelSize.y);
        v.vertex.y = -v.vertex.y;
        v.vertex = UnityObjectToClipPos(v.vertex);
        return v;
      }
```

## Mesh Renderer の削除

これで Mesh Renderer は使わなくなったので、ここで削除します。Hierarchy ウィンドウで <code>TriangleMesh</code> オブジェクトを選択し、Inspector で Triangle Mesh Renderer (Script) → Mesh Renderer → Mesh Filter の順に削除 (右上の <code>︙</code> から Remove Component を選択) してください。この結果 <code>TriangleMesh</code> オブジェクトは Empty になります。

## 次に、スクリプトの TriangleMeshRenderer を修正します。まず、このスクリプトを組み込んだ時に Mesh Filter と Mesh Renderer が自動的に組み込まれないように、<code>[RequireComponent ... ]</code> を削除します。また、このスクリプトから直接マテリアルを参照するために、メンバ変数 <code>material</code> を <code>[SerializeField]</code> にするか、<code>public</code> にします。

```cpp
//[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
//public class RsPointCloudRenderer : MonoBehaviour
public class TriangleMeshRenderer : MonoBehaviour
{
  public RsFrameProvider Source;
  //private Mesh mesh;
  private GraphicsBuffer vertexBuffer = null;
  private GraphicsBuffer indexBuffer = null;
  [SerializeField]
  private Material material;
  private Texture2D uvmap;
 
  [NonSerialized]
  private Vector3[] vertices;
 
  FrameQueue q;
```

## マテリアルはこのスクリプトのプロパティで設定しますから、コンポーネントから取り出す必要はありません。

```cpp
  private void ResetMesh(int width, int height)
  {
    Assert.IsTrue(SystemInfo.SupportsTextureFormat(TextureFormat.RGFloat));
    uvmap = new Texture2D(width, height, TextureFormat.RGFloat, false, true)
    {
      wrapMode = TextureWrapMode.Clamp,
      filterMode = FilterMode.Point,
    };
    //GetComponent<MeshRenderer>().sharedMaterial.SetTexture("_UVMap", uvmap);
    //material = GetComponent<MeshRenderer>().sharedMaterial;
    material.SetTexture("_UVMap", uvmap);
 
```

## この Triangle Mesh Render を Game Object の <code>TriangleMesh</code> に追加します。

## ![Triangle Mesh Renderer の追加](/images/20231028_3.jpg)

## Triangle Mesh Renderer (Script) の Source に <code>RsProcessingPipe</code> を選びます。

## ![Source に RsProcessingPipe を選択](/images/20231028_1.jpg)

## Material には <code>TriangleMeshMat</code> を選びます。

## ![Material に TriangleMeshMat を選択](/images/20231028_2.jpg)

<ul>
<li>[RealSenseSampe (Forward Rendering)](https://github.com/tokoik/RealSenseSample/tree/forward)</li>
</ul>
