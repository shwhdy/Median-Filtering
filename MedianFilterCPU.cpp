#include <cstdlib> // malloc(), free()
#include <iostream>
#include <algorithm> //sort
#include <vector>
#include <stdio.h>
#include "MedianFilter.h"

void BubbleSort(unsigned char* array, int size)
{
	for(int x=0; x<size; x++)
	{

		for(int y=0; y<size-1; y++)

		{

			if(array[y]>array[y+1])

			{

				int temp = array[y+1];

				array[y+1] = array[y];

				array[y] = temp;

			}

		}

	}
}

void iSort(unsigned char* array, int size)
{
	int i,key,j;
	for (i = 1; i < size; i++)
	{
		key = array[i];
		j = i - 1;
		while (j >= 0 && array[j] > key)
		{
			array[j + 1] = array[j];
			j = j - 1;
		}
		array[j + 1] = key;
	}
}

void MedianFilterCPU( Bitmap* image, Bitmap* outputImage )
{
	int height = image->Height();
	int width = image->Width();
	unsigned char PixelVals[9];
	for(int i = 0;i<width;i++)
	{
		for(int j = 0;j<height;j++)
		{
			PixelVals[0] = image->GetPixel(i,j);
			if(i>0)
			{
				PixelVals[1] = image->GetPixel(i-1,j);
			}
			else
			{
				PixelVals[1] = 0;
			}
			if(i<(width-1))
			{
				PixelVals[2] = image->GetPixel(i+1,j);
			}
			else
			{
				PixelVals[2] = 0;
			}
			if(j>0)
			{
				PixelVals[3] = image->GetPixel(i,j-1);
			}
			else
			{
				PixelVals[3] = 0;
			}
			if(j>0 && i>0)
			{
				PixelVals[4] = image->GetPixel(i-1,j-1);
			}
			else
			{
				PixelVals[4] = 0;
			}
			if(j>0 && i<(width-1))
			{
				PixelVals[5] = image->GetPixel(i+1,j-1);
			}
			else
			{
				PixelVals[5] = 0;
			}
			if(j<(height-1))
			{
				PixelVals[6] = image->GetPixel(i,j+1);
			}
			else
			{
				PixelVals[6] = 0;
			}
			if(j<(height-1) && i>0)
			{
				PixelVals[7] = image->GetPixel(i-1,j+1);
			}
			else
			{
				PixelVals[7] = 0;
			}
			if(j<(height-1) && i<(width-1))
			{
				PixelVals[8] = image->GetPixel(i+1,j+1);
			}
			else
			{
				PixelVals[8] = 0;
			}
			iSort(PixelVals,9);
			outputImage->SetPixel(i,j,PixelVals[4]);
		}
	}

}