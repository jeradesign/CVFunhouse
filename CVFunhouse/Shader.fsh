//
//  Shader.fsh
//  Globe
//
//  Created by John Brewer on 1/19/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

varying lowp vec2 v_texCoord;
varying lowp float nDotVP;

uniform sampler2D s_texture;

void main()
{
    gl_FragColor = texture2D(s_texture, v_texCoord) * nDotVP;
}
