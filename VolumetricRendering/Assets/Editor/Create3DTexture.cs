using UnityEngine;
using UnityEditor;

public class Create3DTexture : MonoBehaviour
{
    public const int SIZE = 16;
    public const float RADIUS_ONE = 0.35f;
    public const float RADIUS_TWO = 0.15f;

    [MenuItem("SDF/MakeSphereTexture")]
    public static void EditorTest()
    {
        var selectedGO = Selection.gameObjects[0];
        var mat = selectedGO.GetComponent<MeshRenderer>().materials[0];
        var tex = new Texture3D(SIZE, SIZE, SIZE, TextureFormat.ARGB32, false);
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.filterMode = FilterMode.Trilinear;

        var cols = new Color[SIZE*SIZE*SIZE];
        var index = 0;
        var centerOne = new Vector3(0.6f, 0.5f, 0.5f);
        var centerTwo = new Vector3(0.25f, 0.45f, 0.25f);
        var sizeMax = SIZE - 1;
        for (int z = 0; z < SIZE; z++)
        {
            var normalizedZ = (float)z / sizeMax;
            for (int y = 0; y < SIZE; y++)
            {
                var normalizedY = (float)y / sizeMax;
                for (int x = 0; x < SIZE; x++)
                {
                    var normalizedX = (float)x / sizeMax;
                    var point = new Vector3(normalizedX, normalizedY, normalizedZ);

                    //sphere rule
                    var dist = Vector3.Distance(point, centerOne) - RADIUS_ONE;
                    dist = Mathf.Min(dist, (Vector3.Distance(point, centerTwo) - RADIUS_TWO));

                    //cube rule
                    //var xMin = Mathf.Min(1f - normalizedX, normalizedX - 0f);
                    //var yMin = Mathf.Min(1f - normalizedY, normalizedY - 0f);
                    //var zMin = Mathf.Min(1f - normalizedZ, normalizedZ - 0f);
                    //var dist = Mathf.Min(xMin, yMin, zMin);

                    //point in center rule
                    //var dist = Vector3.Distance(point, center);

                    //Debug.Log("Dist: " + dist + " at " + normalizedX + ", " + normalizedY + ", " + normalizedZ);

                    dist /= 2f;
                    dist += 0.5f;
                    cols[index] = new Color(normalizedX, normalizedY, normalizedZ, dist);
                    index++;
                }
            }
        }

        tex.SetPixels(cols);
        tex.Apply();
        mat.SetTexture("_Volume", tex);
    }
}
