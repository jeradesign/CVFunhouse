//
//  Shader.vsh
//  VideoCube
//
//  Created by John Brewer on 2/22/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoord0;

varying lowp vec4 colorVarying;
varying lowp vec2 texVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    vec4 diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
    
    float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                 
    colorVarying = diffuseColor * nDotVP;
    texVarying = texCoord0;
    
    gl_Position = modelViewProjectionMatrix * position;
}
