using UnityEngine;

public class MeshBoundsProvider : MonoBehaviour
{
    public Material TargetMaterial;

    private void Awake()
    {
        var mesh = GetComponent<MeshFilter>().mesh;
        var bounds = mesh.bounds;
        var minX = bounds.min.x;
        var minZ = bounds.min.z;

        var maxX = bounds.max.x;
        var maxZ = bounds.max.z;

        TargetMaterial.SetFloat("_MinX", minX);
        TargetMaterial.SetFloat("_MaxX", maxX);
        TargetMaterial.SetFloat("_MinZ", minZ);
        TargetMaterial.SetFloat("_MaxZ", maxZ);
    }
}
