---
title: "RealSense (3) メッシュ化した点群を Geometry Instancing で描いてみる"
date: 2023-11-15 00:00:00 +0900
category: Unity
tags: [Unity, RealSense]
published: true
---

## Geometry Instancing してみる

１つの RealSense で取得した点群は整列しているので、それをもとに作った三角形メッシュも三角形が規則正しく並んだものになっています。そのため、このメッシュのインデックスを作っている `CreateTriangleMeshIndex()` は、頂点番号を等間隔に生成しています。このように同じ図形を多数描く場合は、１つ１つを独立したデータとして描くより、一つの図形を GPU 内で複製して描いた方が効率が良くなります。GPU のこの機能を **Geometry Instancing** と呼びます。

## スクリプトの修正

いま描いているメッシュは、縦横に並んだ点群の隣接する 4 点が作る四角形を２つの三角形で描いています。したがって、１つの四角形を GPU 内で複製して描きます。四角形を１つしか使わないので、インデックスは必要ありません。そのためインデックスを格納する `indexBuffer` は削除して、代わりに複製する四角形の数を記録するメンバ変数 `instances` を追加します。

```csharp
//[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
//public class RsPointCloudRenderer : MonoBehaviour
public class TriangleMeshRenderer : MonoBehaviour
{
  public RsFrameProvider Source;
  //private Mesh mesh;
  private GraphicsBuffer vertexBuffer = null;
  //private GraphicsBuffer indexBuffer = null;
  private int instances = 0;
  [SerializeField]
  private Material material;
  private Texture2D uvmap;
```

`indexBuffer` を削除したので、それにインデックスを格納する処理も削除します。`CreateTriangleMeshIndex()` も使わないので、この定義も削除しても構いません。代わりに四角形の数を `instances` に求めておきます。

```csharp
  private void ResetMesh(int width, int height)
  {
    // （中略）

    //var indices = new int[vertices.Length];
    //for (int i = 0; i < vertices.Length; i++)
    //  indices[i] = i;
    //var indices = CreateTriangleMeshIndex(width - 1, height - 1);
    //if (indexBuffer != null)
    //  indexBuffer.Release();
    //indexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Index,
    //  indices.Length, sizeof(int));
    //indexBuffer.SetData(indices);
    instances = (width - 1) * (height - 1);

    //mesh.MarkDynamic();
    //mesh.vertices = vertices;
```

`indexBuffer` は削除したので、破棄する必要もなくなります。

```csharp
  void OnDestroy()
  {
    if (q != null)
    {
      q.Dispose();
      q = null;
    }

    //if (mesh != null)
    //  Destroy(null);
    //if (indexBuffer != null)
    //  indexBuffer.Release();
    if (vertexBuffer != null)
    {
      vertexBuffer.Release();
      Destroy(null);
    }
  }
```

`Graphics.DrawProceduralNow()` では三角形 `MeshTopology.Triangles` ではなく四角形 `MeshTopology.Quads` を描きます。四角形１つなので、頂点の数は 4 です。それを `instances` 個複製して描きます。`MeshTopology.Quads` は、[マニュアル](https://docs.unity3d.com/ScriptReference/MeshTopology.Quads.html)には

> Note that quad topology is emulated on many platforms, so it's more efficient to use a triangular mesh.

とか書かれていてあまり使う気がしないのですけど、これを三角形２つで表したりするとシェーダ内で頂点番号を求めるときに面倒なので、これを使います。

```csharp
  void OnRenderObject()
  {
    //if (indexBuffer != null)
    if (instances > 0)
    {
      material.SetPass(0);
      //Graphics.DrawProceduralNow(MeshTopology.Triangles, indexBuffer, indexBuffer.count);
      Graphics.DrawProceduralNow(MeshTopology.Quads, 4, instances);
    }
  }
```

## シェーダの修正

`Graphics.DrawProceduralNow()` は１つの四角形を `instances` 個複製して描画するので、バーテックスシェーダに渡される頂点番号 `SV_VertexID` は 0～3 の範囲になります。そこでバーテックスシェーダの引数にインスタンスの番号 `SV_InstanceID` を追加し、これと `SV_VertexID` を組み合わせて実際の頂点番号を求めます。四角形の最初の頂点番号は `SV_InstanceID` ですから、`SV_VertexID` と実際の頂点番号との対応は次のようになります。`_UVMap_TexelSize.z` は点群の横方向の点の数です。

| `SV_VertexID` | 実際の頂点番号 |
| :---: | :--- |
| 0 | `SV_InstanceID` |
| 1 | `SV_InstanceID` + 1 |
| 2 | `SV_InstanceID` + `_UVMap_TexelSize.z` + 1 |
| 3 | `SV_InstanceID` + `_UVMap_TexelSize.z` |

```hlsl
      //v2f vert(appdata v)
      v2f vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
      {
        // vertex_id は 0～3 なので instance_id と組み合わせて実際の頂点番号を求める
        uint b0 = vertex_id & 1;
        uint b1 = vertex_id >> 1;
        vertex_id = instance_id + b1 * _UVMap_TexelSize.z + (b0 ^ b1);

        v2f v;
        v.vertex = float4(_Vertex[vertex_id], 1.0);
```

- [RealSenseSample (Geometry Instancing)](https://github.com/tokoik/RealSenseSample/tree/instancing)
