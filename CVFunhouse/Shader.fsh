//
//  Shader.fsh
//  VideoCube
//
//  Created by John Brewer on 2/22/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

varying lowp vec4 colorVarying;
varying lowp vec2 texVarying;

uniform sampler2D texture;

void main()
{
    gl_FragColor = colorVarying * texture2D(texture, texVarying);
}
