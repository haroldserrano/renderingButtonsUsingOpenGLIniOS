//
//  Shader.fsh
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.haroldserrano.com. All rights reserved.
//
precision highp float;

//1. declare a uniform sampler2D that contains the texture data for the non-pressed button image
uniform sampler2D ButtonATextureMap;

//2. declare a second uniform sampler2D that contains the texture data for the pressed button image
uniform sampler2D ButtonAPressedTextureMap;

//3. declare a uniform that contains the current state of the button
uniform int CurrentButtonState;

//4. declare varying type which will transfer the texture coordinates from the vertex shader
varying mediump vec2 vTexCoordinates;

void main()
{
   //5. test for the current value of the "CurrentButtonState" uniform
    if (CurrentButtonState==0) {
        
        //6. set the output of the fragment shader to the non-pressed button image sample
        gl_FragColor=texture2D(ButtonATextureMap,vTexCoordinates.st);
        
    }else if(CurrentButtonState==1){

        //7. set the output of the fragment shader to the pressed button image sample
        gl_FragColor=texture2D(ButtonAPressedTextureMap,vTexCoordinates.st);
    }
 
}