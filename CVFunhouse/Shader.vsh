//
//  Shader.vsh
//  Globe
//
//  Created by John Brewer on 1/19/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

attribute vec4 position;
attribute vec3 normal;
attribute vec2 a_texCoord;

varying lowp vec2 v_texCoord;
varying lowp float nDotVP;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    
    nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
    
    gl_Position = modelViewProjectionMatrix * position;
    v_texCoord = a_texCoord;
}
