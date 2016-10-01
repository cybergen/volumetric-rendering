using UnityEngine;

public class DepthCamera : MonoBehaviour
{
    public Camera Self;
    public Renderer PlaneMaterial;
    public ComputeShader DepthCombiner;

    public Renderer SnowPlane;
    public ComputeShader DepthCombinerStageTwo;

    private Texture _sourceHeightTexture;
    private RenderTexture _editableHeightTextureOne;
    private RenderTexture _editableHeightTextureTwo;
    private RenderTexture _currentHeightTexture;
    private bool _firstTime = true;

    private RenderTexture _depthTex;
    private RenderTexture _textureToApplyToMaterial;
    private RenderTexture _alternativeApplyTexture;
    private RenderTexture _currentTexture; 

    private int _depthTextureRes = 128;
    private int _kernelIndex;

    private void Awake()
    {
        Self.depthTextureMode = DepthTextureMode.Depth;
        _depthTex = new RenderTexture(_depthTextureRes, _depthTextureRes, 16);

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

        _sourceHeightTexture = SnowPlane.sharedMaterial.mainTexture;

        Self.targetTexture = _depthTex;

        _kernelIndex = DepthCombiner.FindKernel("CSMain");
        DepthCombiner.SetTexture(_kernelIndex, "Depth", _depthTex);        
    }

    private void Update()
    {
        var currentIsOne = _currentTexture == _textureToApplyToMaterial;
        _currentTexture = (currentIsOne ? _alternativeApplyTexture : _textureToApplyToMaterial);
        var _sourceTex = (currentIsOne ? _textureToApplyToMaterial : _alternativeApplyTexture);

        DepthCombiner.SetTexture(_kernelIndex, "ExistingDepth", _sourceTex);
        DepthCombiner.SetTexture(_kernelIndex, "RenderTarget", _currentTexture);

        DepthCombiner.Dispatch(_kernelIndex, _depthTextureRes / 8, _depthTextureRes / 8, 1);
        PlaneMaterial.sharedMaterial.mainTexture = _currentTexture;

        
    }
}
