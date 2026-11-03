// 简化实现：基础着色器
// 原本实现：复杂的多功能着色器
// 简化实现：基础的光照和纹理着色器

// 矩阵缓冲区
cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

// 光照缓冲区
cbuffer LightBuffer : register(b1)
{
    float3 lightDirection;
    float padding;
    float4 diffuseColor;
    float4 ambientColor;
};

// 材质属性
cbuffer MaterialBuffer : register(b2)
{
    float4 materialColor;
    float3 materialSpecular;
    float materialShininess;
};

// 纹理采样器
Texture2D shaderTexture;
SamplerState SampleType;

// 顶点输入结构
struct VertexInputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

// 像素输入结构
struct PixelInputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

// 顶点着色器
PixelInputType VertexShaderFunction(VertexInputType input)
{
    PixelInputType output;
    
    // 变换位置到世界空间
    input.position.w = 1.0f;
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    // 传递纹理坐标
    output.tex = input.tex;
    
    // 变换法线到世界空间
    output.normal = mul(input.normal, (float3x3)worldMatrix);
    output.normal = normalize(output.normal);
    
    return output;
}

// 像素着色器
float4 PixelShaderFunction(PixelInputType input) : SV_TARGET
{
    float4 textureColor = shaderTexture.Sample(SampleType, input.tex);
    
    // 简化的光照计算
    float lightIntensity = saturate(dot(input.normal, -lightDirection));
    float4 lightColor = saturate(ambientColor + diffuseColor * lightIntensity);
    
    // 应用材质颜色
    float4 finalColor = textureColor * materialColor * lightColor;
    
    // 应用简单的镜面反射
    float3 viewDirection = normalize(float3(0, 0, 1) - input.position.xyz);
    float3 reflectDirection = reflect(lightDirection, input.normal);
    float specular = pow(saturate(dot(reflectDirection, viewDirection)), materialShininess);
    finalColor += float4(materialSpecular * specular, 1.0f);
    
    return finalColor;
}

// 技术定义
technique10 BasicTechnique
{
    pass Pass0
    {
        SetVertexShader(CompileShader(vs_4_0, VertexShaderFunction()));
        SetPixelShader(CompileShader(ps_4_0, PixelShaderFunction()));
    }
}