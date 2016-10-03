using UnityEngine;
using UnityEngine.Rendering;

public class DepthCamera : MonoBehaviour
{
    public Camera Self;
    public Renderer PlaneMaterial;
    public ComputeShader DepthCombiner;

    public Renderer SnowPlane;
    public ComputeShader DepthCombinerStageTwo;
    public Texture2D HeightMap;
    public Renderer DebugPlaneTwo;

    public Renderer DebugPlaneThree;

    private RenderTexture _editableHeightTextureOne;
    private RenderTexture _editableHeightTextureTwo;
    private RenderTexture _currentHeightTexture;
    private bool _firstTime = true;

    private RenderTexture _depthTex;
    private RenderTexture _textureToApplyToMaterial;
    private RenderTexture _alternativeApplyTexture;
    private RenderTexture _currentTexture; 

    private int _depthTextureRes = 512;
    private int _kernelIndexOne;
    private int _kernelIndexTwo;

    private void Awake()
    {
        Self.depthTextureMode = DepthTextureMode.Depth;
        _depthTex = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);
        _depthTex.Create();

        _textureToApplyToMaterial = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);
        _textureToApplyToMaterial.enableRandomWrite = true;
        _textureToApplyToMaterial.Create();

        _alternativeApplyTexture = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);
        _alternativeApplyTexture.enableRandomWrite = true;
        _alternativeApplyTexture.Create();

        _editableHeightTextureOne = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);
        _editableHeightTextureOne.enableRandomWrite = true;
        _editableHeightTextureOne.Create();

        _editableHeightTextureTwo = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);
        _editableHeightTextureTwo.enableRandomWrite = true;
        _editableHeightTextureTwo.Create();

        Self.targetTexture = _depthTex;

        _kernelIndexOne = DepthCombiner.FindKernel("CSMain");
        DepthCombiner.SetTexture(_kernelIndexOne, "Depth", _depthTex);

        _kernelIndexTwo = DepthCombiner.FindKernel("CSMain");
        DepthCombinerStageTwo.SetTexture(_kernelIndexTwo, "ExistingHeight", HeightMap);

        DebugPlaneThree.sharedMaterial.mainTexture = _depthTex;
    }

    private void Update()
    {
        //First update the total depth texture we've got
        var currentIsOne = _currentTexture == _textureToApplyToMaterial;
        _currentTexture = (currentIsOne ? _alternativeApplyTexture : _textureToApplyToMaterial);
        var _sourceTex = (currentIsOne ? _textureToApplyToMaterial : _alternativeApplyTexture);

        DepthCombiner.SetTexture(_kernelIndexOne, "ExistingDepth", _sourceTex);
        DepthCombiner.SetTexture(_kernelIndexOne, "RenderTarget", _currentTexture);

        DepthCombiner.Dispatch(_kernelIndexOne, _depthTextureRes / 8, _depthTextureRes / 8, 1);
        PlaneMaterial.sharedMaterial.mainTexture = _currentTexture;

        DepthCombinerStageTwo.SetTexture(_kernelIndexTwo, "Depth", _currentTexture);
        var finalTexture = new RenderTexture(_depthTextureRes, _depthTextureRes, 24);
        finalTexture.enableRandomWrite = true;
        finalTexture.Create();
        DepthCombinerStageTwo.SetTexture(_kernelIndexTwo, "RenderTarget", finalTexture);
        DepthCombinerStageTwo.Dispatch(_kernelIndexTwo, _depthTextureRes / 8, _depthTextureRes / 8, 1);
        SnowPlane.sharedMaterial.SetTexture("_SnowMap", finalTexture);
        DebugPlaneTwo.sharedMaterial.mainTexture = finalTexture;

        RenderTexture gbuffer0 = RenderTexture.GetTemporary(_depthTextureRes, _depthTextureRes, 5, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        CommandBuffer commandBuffer = new CommandBuffer();
        commandBuffer.Blit(BuiltinRenderTextureType.Depth, gbuffer0);
        Graphics.ExecuteCommandBuffer(commandBuffer);
        DebugPlaneTwo.sharedMaterial.mainTexture = gbuffer0;

        //computeshader.SetTexture(0, "Input", gbuffer0);
        //computeshader.SetTexture(0, "Result", rtout0);
        //computeshader.Dispatch(0, width, height, 1);
        RenderTexture.ReleaseTemporary(gbuffer0);
    }
}
