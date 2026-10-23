using System.Collections.Generic;
using UnityEngine;

public class AsteroidGenerator : MonoBehaviour
{
    private MeshFilter meshFilter;

    private float cubeSize = 5.0f;

    public void Awake()
    {
        meshFilter = GetComponent<MeshFilter>();

        //meshFilter.mesh = Generate();
        //meshFilter.mesh = new Mesh();
        //var info = GeneratePlane(
        //    new Vector3(0, 0, 0),
        //    new Vector3(0, 1, 0),
        //    new Vector3(1, 0, 0),
        //    2, 10);
        //meshFilter.mesh.vertices = info.vertices.ToArray();
        //meshFilter.mesh.triangles = info.triangles.ToArray();

        meshFilter.mesh = GenerateCube(cubeSize, 10);
    }

    // Use this for initialization
    public void Start()
    {

    }

    // Update is called once per frame
    public void Update()
    {

    }

    private Mesh GenerateCube(float cubeSize, int subdivisionCount)
    {
        var mesh = new Mesh();

        var halfSize = cubeSize / 2;

        var subdivSize = cubeSize / subdivisionCount;

        var top = GeneratePlane(
            new Vector3(-halfSize, halfSize, -halfSize),
            new Vector3(0, 0, 1),
            new Vector3(1, 0, 0),
            subdivSize,
            subdivisionCount,
            0 * subdivisionCount * subdivisionCount
        );

        var bottom = GeneratePlane(
            new Vector3(-halfSize, -halfSize, halfSize),
            new Vector3(0, 0, -1),
            new Vector3(1, 0, 0),
            subdivSize,
            subdivisionCount,
            1 * subdivisionCount * subdivisionCount
        );

        var allVertices = new List<Vector3>();
        allVertices.AddRange(top.vertices);
        allVertices.AddRange(bottom.vertices);

        var allTriangles = new List<int>();

        allTriangles.AddRange(top.triangles);
        allTriangles.AddRange(bottom.triangles);

        mesh.vertices = allVertices.ToArray();
        mesh.triangles = allTriangles.ToArray();

        return mesh;
    }

    private Mesh GenerateSimpleCube()
    {
        var mesh = new Mesh();

        mesh.vertices = new Vector3[8]
        {
            new Vector3(-cubeSize / 2, -cubeSize / 2, cubeSize / 2),
            new Vector3(-cubeSize / 2, cubeSize / 2, cubeSize / 2),
            new Vector3(cubeSize / 2, cubeSize / 2, cubeSize / 2),
            new Vector3(cubeSize / 2, -cubeSize / 2, cubeSize / 2),

            new Vector3(-cubeSize / 2, -cubeSize / 2, -cubeSize / 2),
            new Vector3(-cubeSize / 2, cubeSize / 2, -cubeSize / 2),
            new Vector3(cubeSize / 2, cubeSize / 2, -cubeSize / 2),
            new Vector3(cubeSize / 2, -cubeSize / 2, -cubeSize / 2),
        };

        mesh.triangles = new int[36]
        {
            2, 1, 0,
            0, 3, 2,

            4, 5, 6,
            6, 7, 4,

            6, 2, 3,
            3, 7, 6,

            0, 1, 5,
            5, 4, 0,

            5, 1, 2,
            2, 6, 5,

            7, 3, 0,
            0, 4, 7,
        };

        return mesh;
    }

    private VerticesTriangleInfo GeneratePlane(Vector3 start, Vector3 rowVector, Vector3 colVector, float size, int count, int startIndex)
    {
        rowVector.Normalize();
        colVector.Normalize();

        var result = new VerticesTriangleInfo()
        {
            triangles = new List<int>(),
            vertices = new List<Vector3>()
        };

        for (int row = 0; row < count; ++row)
            for (int col = 0; col < count; ++col)
                result.vertices.Add(start + (colVector * size * col) + (rowVector * size * row));

        for (int row = 0; row < count - 1; ++row)
            for (int col = 0; col < count - 1; ++col)
                result.triangles.AddRange(new int[] {
                    startIndex + count * row + col + 1,
                    startIndex + count * row + col,
                    startIndex + count * (row + 1) + col,

                    startIndex + count * (row + 1) + col,
                    startIndex + count * (row + 1) + col + 1,
                    startIndex + count * row + col + 1
                });

        return result;
    }

    internal struct VerticesTriangleInfo
    {
        public List<Vector3> vertices;

        public List<int> triangles;
    }
}
