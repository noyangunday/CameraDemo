/*

  The MIT License (MIT)

  Copyright (c) 2016 VISUEM LTD

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

*/

#include "RenderManager.h"
#include <math.h>

namespace
{

        const GLfloat _quad_data[12] =
        {
                -1.0f, -1.0f, 0.0f,
                 1.0f, -1.0f, 0.0f,
                 1.0f,  1.0f, 0.0f,
                -1.0f,  1.0f, 0.0f,
        };

        const GLchar* _vs_source =
                "attribute vec3 aPos;\n"
                "void main()\n"
                "{\n"
                "       gl_Position = vec4(aPos, 1.0);\n"
                "}\n";

        const GLchar* _fs_source =
                "uniform sampler2D uSampler; \n"
                "uniform mediump float uTime; \n"
                "void main()\n"
                "{\n"
                "       mediump vec2 res = vec2(1080.0, 1920.0); \n" // Hard coded for now.
                "       mediump vec2 dist = -1.0 + 2.0 * gl_FragCoord.xy / res; \n"
                "       mediump float l = length(dist); \n"
                "       mediump vec2 uv = gl_FragCoord.xy / res; \n"
                "       uv += (dist/l) * cos(l * 5.0 - uTime * 3.0) * 0.03; \n"
                "       uv = vec2(1.0, 1.0) - uv.ts; \n"
                "       mediump vec4 texel = texture2D(uSampler, uv); \n"
                "       gl_FragColor = texel; \n"
                "}\n";

        const float _grad_pi = 0.0174533f;

}

RenderManager::RenderManager() : mTime(0.0f)
{
        BuildBuffer();
        BuildProgram();
}

RenderManager::~RenderManager()
{
        glDeleteBuffers(1, &mVertexBuffer);
        glDeleteVertexArraysOES(1, &mVertexArray);
        glDeleteProgram(mProgram);
}

void RenderManager::BuildBuffer()
{
        glGenVertexArraysOES(1, &mVertexArray);
        glBindVertexArrayOES(mVertexArray);

        glGenBuffers(1, &mVertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, mVertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(_quad_data), _quad_data, GL_STATIC_DRAW);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 12, (const GLvoid*)0);
}

void RenderManager::BuildProgram()
{
        mProgram = glCreateProgram();
        glAttachShader(mProgram, CompileShader(GL_VERTEX_SHADER, _vs_source));
        glAttachShader(mProgram, CompileShader(GL_FRAGMENT_SHADER, _fs_source));
        glBindAttribLocation(mProgram, 0, "aPos");
        glLinkProgram(mProgram);
}

GLuint RenderManager::CompileShader(GLuint type, const GLchar* source)
{
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, 1, &source, 0);
        glCompileShader(shader);
        return shader;
}

void RenderManager::UpdateEffect()
{
        mTime++;
        if (mTime >= 360.0f)
        {
                mTime = 0.0f;
        }
}

void RenderManager::Render()
{
        glClear(GL_COLOR_BUFFER_BIT);
        glBindVertexArrayOES(mVertexArray);
        glUseProgram(mProgram);
        glUniform1i(glGetUniformLocation(mProgram, "uSampler"), 0);
        glUniform1f(glGetUniformLocation(mProgram, "uTime"), sin(mTime * _grad_pi));
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}
