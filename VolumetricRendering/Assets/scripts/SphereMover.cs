using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public class SphereMover : MonoBehaviour
{
    public ComputeShader TextureGenerator;
    public int Size;
    public float RadiusOne;
    public float RadiusTwo;
    public bool AnimateSpheres;
    public bool VoxelMode;
    public float TimeMultiplier;

    private Material _material;

    private void Start()
    {
        _material = gameObject.GetComponent<MeshRenderer>().materials[0];
    }

    private void Update()
    {
        UpdateViaCPU();
    }

    private void UpdateViaCPU()
    {
        if (!AnimateSpheres) return;

        var tex = new Texture3D(Size, Size, Size, TextureFormat.ARGB32, false);
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.filterMode = VoxelMode ? FilterMode.Point : FilterMode.Trilinear;

        var cols = new Color[Size * Size * Size];
        var index = 0;
        var centerOne = new Vector3(0.55f, 0.5f, 0.5f);

        var centerTwo = new Vector3(0.25f, 0.45f, 0.25f);
        var centerTwoDest = new Vector3(0.65f, 0.65f, 0.65f);

        var sin = Mathf.Sin(Time.time * TimeMultiplier) * 0.5f + 0.5f;
        var currentCenterTwo = Vector3.Lerp(centerTwo, centerTwoDest, sin);

        var sizeMax = Size - 1;
        for (int z = 0; z < Size; z++)
        {
            var normalizedZ = (float)z / sizeMax;
            for (int y = 0; y < Size; y++)
            {
                var normalizedY = (float)y / sizeMax;
                for (int x = 0; x < Size; x++)
                {
                    var normalizedX = (float)x / sizeMax;
                    var point = new Vector3(normalizedX, normalizedY, normalizedZ);

                    //sphere rule
                    var dist = Vector3.Distance(point, centerOne) - RadiusOne;
                    dist = Mathf.Min(dist, (Vector3.Distance(point, currentCenterTwo) - RadiusTwo));

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

        _material.SetTexture("_Volume", tex);
    }

    private void UpdateViaCompute()
    {
        if (!AnimateSpheres) return;

        //Sphere update
        var kernel = TextureGenerator.FindKernel("CSMain");
        var tex = new RenderTexture(Size, Size, 24, RenderTextureFormat.ARGB32);
        tex.isVolume = true;
        tex.volumeDepth = Size;
        tex.enableRandomWrite = true;
        tex.antiAliasing = 1;
        tex.anisoLevel = 1;
        tex.filterMode = FilterMode.Point;
        tex.generateMips = false;
        tex.useMipMap = false;
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.Create();

        TextureGenerator.SetTexture(kernel, "Texture", tex);
        TextureGenerator.Dispatch(kernel, Size / 8, Size / 8, Size / 8);

        _material.SetTexture("_Volume", tex);
    }
}
