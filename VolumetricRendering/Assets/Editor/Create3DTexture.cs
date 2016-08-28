using UnityEngine;
using UnityEditor;

public class Create3DTexture : MonoBehaviour
{
    public const int SIZE = 32;
    public const float RADIUS = 0.45f;

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
        var center = new Vector3(0.5f, 0.5f, 0.5f);
        for (int z = 0; z < SIZE; z++)
        {
            var normalizedZ = (float)z / SIZE;
            for (int y = 0; y < SIZE; y++)
            {
                var normalizedY = (float)y / SIZE;
                for (int x = 0; x < SIZE; x++)
                {
                    var normalizedX = (float)x / SIZE;
                    var point = new Vector3(normalizedX, normalizedY, normalizedZ);

                    //sphere rule
                    var dist = Vector3.Distance(point, center) - RADIUS;
                    //Debug.Log("Dist: " + dist + " at " + normalizedX + ", " + normalizedY + ", " + normalizedZ);

                    //cube rule
                    //var dist = Mathf.Min(-normalizedX, -normalizedY, -normalizedZ);

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
