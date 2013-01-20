/*
 *  drawglobe.c
 *  world
 *
 *  Copyright 2009 Jera Design LLC. All rights reserved.
 *
 */

#define DRAW_GUIDES 0

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#import <OpenGLES/ES2/gl.h>

GLubyte* glmReadPPM(char* filename, int* width, int* height);

#include "drawglobe.h"

#define THETA_STEPS 100
#define PHI_STEPS 50
//#define THETA_STEPS 4
//#define PHI_STEPS 3
#define ARRAY_LENGTH ((THETA_STEPS + 1) * (PHI_STEPS + 1))
#define INDEX_LENGTH (3 * ARRAY_LENGTH)

extern GLuint textureId;

static GLfloat vertices[ARRAY_LENGTH][3];
static GLfloat texCoords[ARRAY_LENGTH][2];
static GLfloat normals[ARRAY_LENGTH][3];
static GLushort pointIndices[ARRAY_LENGTH];
static GLushort lineIndices[PHI_STEPS + 1];
static GLushort indices[INDEX_LENGTH];

static int maxIndex;

void generateGlobeVertexArrays(GLuint vertexInd, GLuint normalInd, GLuint tex0Ind) {
  printf("before generateGlobeVertexArrays, glGetError = %x\n", glGetError());
  int count = 0;
  float TWO_PI = 2.0 * M_PI;
  float a;
  for (a = 0.0; a < PHI_STEPS + 1; a++) {
    float t1 = a / PHI_STEPS;
    float y1 = cos(M_PI * a / PHI_STEPS);
    float b;
    for (b = 0.0; b < THETA_STEPS + 1; b++) {
      float s1 = b / THETA_STEPS;
      float x1 = sin(TWO_PI * b / THETA_STEPS + M_PI) * sin(M_PI * a/PHI_STEPS);
      float z1 = cos(TWO_PI * b / THETA_STEPS + M_PI) * sin(M_PI * a/PHI_STEPS);
      vertices[count][0] = x1;
      vertices[count][1] = y1;
      vertices[count][2] = z1;
      texCoords[count][0] = s1;
      texCoords[count][1] = t1;
      normals[count][0] = x1;
      normals[count][1] = y1;
      normals[count][2] = z1;
      ++count;
    }
  }
  printf("after glEnableClientState, glGetError = %x\n", glGetError());
  
  glVertexAttribPointer(vertexInd, 3, GL_FLOAT, GL_FALSE, 0, vertices);
  printf("after vertexInd, glGetError = %x\n", glGetError());
  glVertexAttribPointer(normalInd, 3, GL_FLOAT, GL_FALSE, 0, normals);
  printf("after normalInd, glGetError = %x\n", glGetError());
  glVertexAttribPointer(tex0Ind, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
  printf("after tex0Ind, glGetError = %x\n", glGetError());

  int i;
  count = 0;
  for (i = 0; i < ARRAY_LENGTH; i++) {
    pointIndices[count] = i;
    count += 1;
  }
  
  count = 0;
  for (i = 0; i < PHI_STEPS + 1; i++) {
    lineIndices[count] = i * (THETA_STEPS + 1);
    count += 1;
  }
  
  int j;
  count = 0;
  for (j = 0; j < PHI_STEPS; j++) {
    int firstElement = j * (THETA_STEPS + 1);
    for (i = 0; i < THETA_STEPS + 1; i++) {
      indices[count] = firstElement + i;
      indices[count + 1] = firstElement + i + THETA_STEPS + 1;
      count += 2;
    }
  }
  
  maxIndex = count;
  printf("after generateGlobeVertexArrays, glGetError = %x\n", glGetError());
}

void drawGlobeWithVertexArrays(void) {
  glEnable(GL_CULL_FACE);
  
  printf("before glDrawElements, glGetError = %x\n", glGetError());
  glEnableVertexAttribArray ( 0 );
  glEnableVertexAttribArray ( 1 );
  glEnableVertexAttribArray ( 2 );
  glEnableVertexAttribArray ( 3 );
  glDrawElements(GL_TRIANGLE_STRIP, maxIndex, GL_UNSIGNED_SHORT, indices);
#if DRAW_GUIDES
  glDrawElements(GL_POINTS, ARRAY_LENGTH, GL_UNSIGNED_SHORT, pointIndices);
  glDrawElements(GL_LINE_STRIP, PHI_STEPS + 1, GL_UNSIGNED_SHORT, lineIndices);
#endif // DRAW_GUIDES
  printf("after glDrawElements, glGetError = %x\n", glGetError());
}
