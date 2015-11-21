# Rendering Buttons using OpenG ES 2.0 in iOS

## Introduction

Have you ever wondered how a button can change its appearance when pressed?

What is happening is that two images were loaded into [texture objects][0]. When a touch is detected, a particular _texture-unit_ becomes active and renders one of the two images on the screen.

### Objective

In this hands-on project, you will learn how to load a multi-image button. When you press the button, it will change its appearance. The final result will be as shown in figure 1.

##### Figure 1. 3D Model with two multi-image buttons

![Multi-image buttons][1]

This is a hands-on project. Feel free to download the [template Xcode project][2] and code along.

### Things to know

* [How to apply textures to a game character using OpenGL ES.][0]


## Implementing a Multi-Image button

Our button will be represented by two different textures as shown in figure 2. One image represents a _pressed_ button, whereas the other one represents and _unpressed_ button. Only one of these textures will be active at a time. These two textures will be stored in different _texture objects_ and activated by two distinct _texture-units_.

##### Figure 2. Textures for button

![][3]

Our code will detect a touch from the user. If the touch coordinates fall within the button boundaries, a _texture-unit_ will be activated and the value of a shader uniform, _CurrentButtonState_ will change. The uniform _CurrentButtonState_ is used by the fragment shader to determine which texture to sample.

The button’s projective space should be set to an _Orthogonal view_. In _Orthogonal View_, every object in the scene is seen as a two-dimensional object. Unlike any other 3D model, there is no illusion of depth with buttons. 

We will set our _Orthogonal view_ to range from [-1,1]. The upper left hand corner of the orthogonal space is represented by [-1,1]. The lower right-hand corner is represented by [1,-1].

### Implementing a Button class

We will implement a C++ class representing our button. our **Button** class will contain all the necessary methods required to render the object on the screen. 

Just like any other object shown on a screen, we need to load the button’s vertices and UV coordinates into OpenGL buffers. However, these vertices and UV coordinates are usually calculated by you. To set these values, we require the button’s desired dimensions.

Open up the **Button.mm** file and head to the constructor method _Button()_. Copy what is shown in listing 1.

##### Listing 1. Setting the width and height of the button


<pre><code class="language-c">Button::Button(float uButtonXPosition, float uButtonYPosition, float uButtonWidth,float uButtonHeight, const char* uButtonImage, const char* uPressedButtonImage, float uScreenWidth,float uScreenHeight){

//1. screen width and height
screenWidth=uScreenWidth;
screenHeight=uScreenHeight;

//2. button width and height
buttonWidth=uButtonWidth;
buttonHeight=uButtonHeight;

//3. set the names of both button images
buttonImage=uButtonImage;
pressedButtonImage=uPressedButtonImage;

//4. button x and y position. Because our ortho matrix is in the range of [-1,1]. We need to convert from screen coordinates to ortho coordinates.
buttonXPosition=uButtonXPosition*2/screenWidth-1;
buttonYPosition=uButtonYPosition*(-2/screenHeight)+1;

//5. calculate the boundaries of the button
left=buttonXPosition-buttonWidth/screenWidth;
right=buttonXPosition+buttonWidth/screenWidth;

top=buttonYPosition+buttonHeight/screenHeight;
bottom=buttonYPosition-buttonHeight/screenHeight;

//6. set the bool value to false
isPressed=false;

}</code>
</pre>

Our constructor method ask the user to provide the button’s dimension and location. It also asks the user to provide a reference to the images used for the button.

Lines 1-3 simply store the dimension of the button, screen dimension and texture reference into the class data members.

Line 4 transforms the position of the button from screen space to orthogonal space. 

> Transforming the position from screen space to orthogonal space is not necessary. This is simply for convenience. For example, the user can set the button’s position within the range of [0,0] to [480,320] instead of [-1,1] to [1,-1]. 

To determine the touch boundaries for the button, we need to calculate the four corners enclosing the button. The _left, right, top_ and _bottom_ coordinates of the button are calculated in line 5.

### Determining the vertices and UV coords of the button

The vertices of the button are simply the vertices of a unit square, scaled by the dimensions of the button.

Open up the **Button.mm** file. Go to the _setButtonVertexAndUVCoords()_ method and copy what is shown in listing 2.

##### Listing 2. Determining the Vertices and UV coords


<pre><code class="language-c">void Button::setButtonVertexAndUVCoords(){

//1. set the width, height and depth for the image rectangle
float width=buttonWidth/screenWidth;
float height=buttonHeight/screenHeight;
float depth=0.0;

//2. Set the value for each vertex into an array

//Upper-Right Corner vertex of rectangle
buttonVertices[0]=width;
buttonVertices[1]=height;
buttonVertices[2]=depth;

//Lower-Right corner vertex of rectangle
buttonVertices[3]=width;
buttonVertices[4]=-height;
buttonVertices[5]=depth;

//Lower-Left corner vertex of rectangle
buttonVertices[6]=-width;
buttonVertices[7]=-height;
buttonVertices[8]=depth;

//Upper-Left corner vertex of rectangle
buttonVertices[9]=-width;
buttonVertices[10]=height;
buttonVertices[11]=depth;


//3. Set the value for each uv coordinate into an array

buttonUVCoords[0]=1.0;
buttonUVCoords[1]=0.0;

buttonUVCoords[2]=1.0;
buttonUVCoords[3]=1.0;

buttonUVCoords[4]=0.0;
buttonUVCoords[5]=1.0;

buttonUVCoords[6]=0.0;
buttonUVCoords[7]=0.0;

//4. set the value for each index into an array

buttonIndex[0]=0;
buttonIndex[1]=1;
buttonIndex[2]=2;

buttonIndex[3]=2;
buttonIndex[4]=3;
buttonIndex[5]=0;

}</code>
</pre>

Line 1 simply scales the button dimension by the screen dimensions.

Line 2-4 loads the vertex, UV coordinates and index values of the rectangle into arrays. The data of these arrays will be loaded into OpenGL buffers.

If you go to lines 5a-5c in the _setupOpenGL()_ method, you will see the loading of these data into OpenGL buffers, as shown in listing 3.

##### Listing 3. Loading up the vertices and UV coords into openGL buffers


<pre><code class="language-c">void Button::setupOpenGL(){

//...

//5a. Dump the data into the Buffer

glBufferData(GL_ARRAY_BUFFER, sizeof(buttonVertices)+sizeof(buttonUVCoords), NULL, GL_STATIC_DRAW);

//5b. Load vertex data with glBufferSubData
glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(buttonVertices), buttonVertices);

//5c. Load uv data with glBufferSubData
glBufferSubData(GL_ARRAY_BUFFER, sizeof(buttonVertices), sizeof(buttonUVCoords), buttonUVCoords);

//...

}</code>
</pre>

### Loading multiple textures

To load multiple textures, we need to generate and activate multiple _texture buffers_ and _texture-units_, respectively.

Open up file **Button.mm**. Go to the _setupOpenGL()_ method, look for line 14 and copy what is shown in listing 4.

##### Listing 4. Loading multiple textures.


<pre><code class="language-c">void Button::setupOpenGL(){

//...

//SET UNPRESSED BUTTON TEXTURE
//14. Activate GL_TEXTURE0
glActiveTexture(GL_TEXTURE0);

//15 Generate a texture buffer
glGenTextures(1, &amp;textureID[0]);

//16 Bind texture0
glBindTexture(GL_TEXTURE_2D, textureID[0]);

//17. Decode image into its raw image data. "ButtonA.png" is our formatted image.
if(convertImageToRawImage(buttonImage)){

//if decompression was successful, set the texture parameters

//17a. set the texture wrapping parameters
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

//17b. set the texture magnification/minification parameters
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

//17c. load the image data into the current bound texture buffer
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0,
GL_RGBA, GL_UNSIGNED_BYTE, &amp;image[0]);

}

image.clear();

//18. Get the location of the Uniform Sampler2D
ButtonATextureUniformLocation=glGetUniformLocation(programObject, "ButtonATextureMap");

//SET PRESSED BUTTON TEXTURE

//19. Activate GL_TEXTURE1
glActiveTexture(GL_TEXTURE1);

//20 Generate a texture buffer
glGenTextures(1, &amp;textureID[1]);

//21 Bind texture0
glBindTexture(GL_TEXTURE_2D, textureID[1]);

//22. Decode image into its raw image data. "ButtonAPressed.png" is our formatted image.
if(convertImageToRawImage(pressedButtonImage)){

//if decompression was successful, set the texture parameters

//17a. set the texture wrapping parameters
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

//17b. set the texture magnification/minification parameters
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

//17c. load the image data into the current bound texture buffer
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0,
GL_RGBA, GL_UNSIGNED_BYTE, &amp;image[0]);

}

image.clear();

//23. Get the location of the Uniform Sampler2D
ButtonAPressedTextureUniformLocation=glGetUniformLocation(programObject, "ButtonAPressedTextureMap");

//24. Get the location for the uniform containing the current button state
ButtonStateUniformLocation=glGetUniformLocation(programObject, "CurrentButtonState");

//...
}</code>
</pre>

We first activate and create a _texture-unit_ and _texture buffer_ as shown in lines 14-16.

We then decompress the first button-image and set its textures parameters as shown in lines 17a-17c.

The location of the uniform sampler for the first button image is obtain in line 18.

We repeat the same process for the second button-image, but this time with a different texture-unit and texture buffer(lines 19-23).

Line 24 simply gets the location of the uniform which will keep track of the button current state. 

### Setting up the space transformation for the button

The space transformation for the button is quite simple. Our button does not need to be rotate, only translated. Thus, it’s _model_ space is simply set as an _Identity_ matrix. The _Identity_ matrix is then translated to a particular location. 

The _World_ and _Camera_ space are omitted from this transformation. We do not need to take them into account and are thus treated as _Identity_ matrices. Or in this case, not used at all.

> If we were to take the _camera_ space into account, a camera rotation, would result into a button rotation as well.

The _Projective_ space of the button is set to an _Orthogonal_ view. The reason is because the button will be shown as a two-dimensional object and not as a three-dimensional one.

Open up file **Button.mm**. Go to the _setTransformation()_ method and copy what is shown in listing 5.

##### Listing 5. Setting up the space transformation


<pre><code class="language-c">void Button::setTransformation(){

//1. Set up the model space
modelSpace=GLKMatrix4Identity;

//2. translate the button
modelSpace=GLKMatrix4Translate(modelSpace, buttonXPosition, buttonYPosition, 0.0);

//3. Set the projection space to a ortho space
projectionSpace = GLKMatrix4MakeOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);

//4. Transform the model-world-view space to the projection space
modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelSpace);

//5. Assign the model-world-view-projection matrix data to the uniform location:modelviewProjectionUniformLocation
glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);

}</code>
</pre>

The button’s _model_ space is translated to the desire _x_ and _y_ position on the screen (lines 1-2).

We set the _Perspective_ space of the button to a _orthogonal view_ ranging from [-1,1], as shown in line 3.

The _Model-World-Camera-Projection space_ is then calculated in line 4. 

### Rendering the correct button texture

Once the vertices and UV coordinates are loaded into OpenGL buffers and the space transformation set for the button, rendering can start. 

The rendering for the button is performed in the _draw()_ method.

Open up the **Button.mm** file, go to the _draw()_ method and copy what is shown in listing 6.

##### Listing 6. Rendering the button


<pre><code class="language-c">void Button::draw(){

//1. Set the shader program
glUseProgram(programObject);

//2. Bind the VAO
glBindVertexArrayOES(vertexArrayObject);

//3. Enable blending and depth test
glEnable(GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
glDisable(GL_DEPTH_TEST);

//4. If the isPressed value is true, then update the state of the button
if (isPressed==true) {

//5. uniform is updated with a value of 1
glUniform1i(ButtonStateUniformLocation, 1);

//6. Activate the texture unit for the pressed button image
glActiveTexture(GL_TEXTURE1);

//7 Bind the texture object
glBindTexture(GL_TEXTURE_2D, textureID[1]);

//8. Specify the value of the UV Map uniform
glUniform1i(ButtonAPressedTextureUniformLocation, 1);

}else{

//9. if it is not pressed, the uniform is updated with a value of 0
glUniform1i(ButtonStateUniformLocation, 0);

//10. Activate the texture unit for the non-pressed button image
glActiveTexture(GL_TEXTURE0);

//11 Bind the texture object
glBindTexture(GL_TEXTURE_2D, textureID[0]);

//12. Specify the value of the UV Map uniform
glUniform1i(ButtonATextureUniformLocation, 0);

}

//13. Start the rendering process
glDrawElements(GL_TRIANGLES, sizeof(buttonIndex)/4, GL_UNSIGNED_INT,(void*)0);

//14. Disable the blending and enable depth testing
glDisable(GL_BLEND);
glEnable(GL_DEPTH_TEST);

//15. Set the bool value "isPressed" to false to avoid the image to be locked up
isPressed=false;

//16. Disable the VAO
glBindVertexArrayOES(0);

}</code>
</pre>

Rendering a button is the same as rendering a 3D model. The main difference is that we enable _blending_ as shown in line 3. This operation allows incoming pixels to be blend in with pixels already stored in the framebuffer. It makes the button’s pixels blend in with any other 3D model’s pixels.

In the rendering method, only one _texture-unit_ can be activated at a time. We test which _texture-unit_ to activate depending on the value of the _isPressed_ boolean as shown in line 4. We also change the value of the uniform _ButtonStateUniformLocation_. This uniform is used in the fragment shader to determine which texture to sample. This process is shown in lines 5-12.

> Recall that the location of the uniform _> CurrentButtonState_>  is referenced by the _> ButtonStateUniformLocation_> .

Before we leave the rendering method, we must disable blending and enable depth-testing as shown in lines 14.

### Detecting if the button was pressed

Open up the **Button.mm** file, go to the _update()_ method and copy what is shown in listing 7.

##### Listing 7. Detecting a touch


<pre><code class="language-c">void Button::update(float touchXPosition,float touchYPosition){

//1. check if the touch is within the boundaries of the button

if (touchXPosition&gt;=left &amp;&amp; touchXPosition&lt;=right) {

if (touchYPosition&gt;=bottom &amp;&amp; touchYPosition&lt;=top) {

    //2. if so, set the bool value to true
     isPressed=true;
}
}else{
    //3. else, set it to false
    isPressed=false;
}

}</code>
</pre>

To detect if a touch coordinate happened within the boundaries of the button, we simply calculate if the touch happened between the _left, right, top_ and _button_ coordinate of the button.

If the touch did occur within the boundaries of the button, then the boolean variable _isPressed_ is set to true, else it is set to false as shown in lines 1-3.

### Implementing the shaders

The shader files for the button are _ButtonShader.vsh_ and _ButtonShader.fsh_. 

#### Implementing the Vertex Shader

Open up the _ButtonShader.vsh_ file and copy was is shown in listing 8.

##### Listing 8. Implementation of the Vertex Shader


<pre><code class="language-c">//1. declare attributes
attribute vec4 position;
attribute vec2 texCoord;

//2. declare varying type which will transfer the texture coordinates to the fragment shader
varying mediump vec2 vTexCoordinates;

//3. declare a uniform that contains the model-View-projection, model-View and normal matrix
uniform mat4 modelViewProjectionMatrix;

void main()
{

//4. recall that attributes can't be declared in fragment shaders. Nonetheless, we need the texture coordinates in the fragment shader. So we copy the information of "texCoord" to "vTexCoordinates", a varying type.

vTexCoordinates=texCoord;

//5. transform every position vertex by the model-view-projection matrix
gl_Position = modelViewProjectionMatrix * position;

}</code>
</pre>

The vertex shader is very simple. It simply transfers the texture coordinates to the fragment shader with a _varying_ variable and it transforms every vertex by the space transformation matrix as shown in lines 4-5.

#### Implementing the Fragment Shader

Open up the _ButtonShader.fsh_ file and copy was is shown in listing 9.

##### Listing 9. Implementation of the Fragment Shader


<pre><code class="language-c">precision highp float;

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

}</code>
</pre>

In the fragment shader, we simply check for the **CurrentButtonState** value. Depending on this value, we sample the appropriate texture (lines 5-7).

#### Creating Button instances

Finally, let’s create two instance for the button class. We are going to create two instances: _buttonA_ and _buttonB_. Each of these instances will have their own texture-images.

Open up the _ViewController.mm_ file. Go to the _viewDidLoad()_ method, locate line 8 and copy what is shown in listing 10.

##### Listing 10. Creating Button instances


<pre><code class="language-c">- (void)viewDidLoad
{
//...
//8. create an instance (buttonA) of the button class
buttonA=new Button(80,260,80.0,80.0,"ButtonA.png","ButtonAPressed.png",self.view.bounds.size.height,self.view.bounds.size.width);

//9. set the vertex and UV coordinates for the button
buttonA-&gt;setButtonVertexAndUVCoords();

//10. begin the OpenGL setup for the button
buttonA-&gt;setupOpenGL();

//11. create an instance (buttonB) of the button class
buttonB=new Button(400,260,80.0,80.0,"ButtonB.png","ButtonBPressed.png",self.view.bounds.size.height,self.view.bounds.size.width);

//12.set the vertex and UV coordinates for the buttonB
buttonB-&gt;setButtonVertexAndUVCoords();

//13. begin the OpenGL setup for the buttonB
buttonB-&gt;setupOpenGL();

//...
}</code>
</pre>

In line 8, we simply provide the location, dimension and image reference for _buttonA_. We then call the method in charge of creating the vertices and UV coordinates for the button (line 9). Lastly we call the OpenGL setup method (line 10). We repeat the same process for _buttonB_ (lines 11-13).

### Final Result

Run the project. You should now see two buttons on the screen as shown in figure 3. Press on each button. The buttons should change appearance and the 3D model should rotate.

##### Figure 3. A 3D Model with two multi-image buttons

![Multi-image buttons][1]

### Credit


### Questions?


[0]: http://www.haroldserrano.com/blog/how-to-apply-textures-to-a-character-in-ios
[1]: https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/littlemansionButtons.png
[2]: https://dl.dropboxusercontent.com/u/107789379/haroldserrano/MakeOpenGLProject/Adding%20buttons%20to%20a%20game/Template-Skeleton.zip
[3]: https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/multipleImagesForButton.png
[4]: https://dl.dropboxusercontent.com/u/107789379/haroldserrano/MakeOpenGLProject/Adding%20buttons%20to%20a%20game/Final.zip
[5]: http://www.haroldserrano.com/subscription
