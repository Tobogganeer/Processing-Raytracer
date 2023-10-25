// Used to buffer and average rendered frames
class RenderBuffer
{
  private Image[] bufferedFrames; // The frames we have
  private ImageMetadata[] frameMetadata; // Their respective data
  private int frameIndex; // What frame we should render next
  private int width, height;
  private int scale; // Downscale factor

  private Image screenBuffer; // The entire screen (used for post processing, which is just upscaling for now)

  RenderBuffer(int width, int height, int numFrames, int scale)
  {
    this.width = width;
    this.height = height;
    bufferedFrames = new Image[numFrames];
    frameMetadata = new ImageMetadata[numFrames];
    for (int i = 0; i < numFrames; i++) // Create the frames
    {
      bufferedFrames[i] = new Image(width, height);
      frameMetadata[i] = new ImageMetadata(new PVector(), new PVector());
    }

    this.scale = max(scale, 1); // No 0 scale silly
    screenBuffer = new Image(width * scale, height * scale);
  }

  // Most of these small functions were used at a point, but aren't now
  void setFrameIndex(int frameIndex)
  {
    this.frameIndex = frameIndex % getNumFrames();
  }

  int getFrameIndex()
  {
    return frameIndex;
  }

  int getNumFrames()
  {
    return bufferedFrames.length;
  }

  // Sets the last frame's metadata (called after we get the next render frame)
  void setImageMetadata(PVector position, PVector angle)
  {
    setImageMetadataIndex(getFrameNumber(-1), position, angle);
  }

  void setImageMetadataIndex(int index, PVector position, PVector angle)
  {
    frameMetadata[index].set(position, angle);
  }

  Image getRenderFrame()
  {
    // Give em back a frame to shove their pixels into
    Image frame = bufferedFrames[frameIndex];
    frameIndex = (frameIndex + 1) % getNumFrames();
    return frame;
  }

  Image getFrame(int index)
  {
    return bufferedFrames[index];
  }

  // Displays all of the current frames at (x, y)
  void display(int x, int y)
  {
    int numFrames = getNumFrames();

    // We only want to display frames that were at the current position & rotation
    ImageMetadata mostRecent = frameMetadata[getFrameNumber(-1)];

    int matching = 0;
    for (int i = 0; i < numFrames; i++)
    {
      // frameIndex - 1 is most recent
      int frameNumber = getFrameNumber(-i - 1);
      if (frameMetadata[frameNumber].matches(mostRecent))
        matching++; // Count how many frames are current
    }

    numFrames = matching; // Only render frames from the same position and rotation

    Colour[] pixelBuffer = new Colour[numFrames]; // Pre-allocate array for re-use

    for (int i = 0; i < width; i++)
    {
      for (int j = 0; j < height; j++)
      {
        // Fill in every block of pixels (ex for scale 2, fill the 2x2 blocks of screen pixels)
        fillPixelBlocks(i, j, scale, numFrames, pixelBuffer);
      }
    }

    // If there was extra post processing, do it here

    // Draw the buffered image to the screen
    drawImage(x, y, screenBuffer);
  }

  void fillPixelBlocks(int x, int y, int scale, int numFrames, Colour[] pixelBuffer)
  {
    if (scale == 1)
    {
      // Set the pixel directly if there is no downscaling
      screenBuffer.set(x, y, avgPixel(x, y, numFrames, pixelBuffer));
      return;
    }

    Colour tl, tr, bl, br; // Top, bottom left, right

    // Set top left to (x, y)
    tl = avgPixel(x, y, numFrames, pixelBuffer);

    // Fill other neighbouring pixels, clamping if they are an edge pixel
    if (x + 1 < width) tr = avgPixel(x + 1, y, numFrames, pixelBuffer);
    else tr = tl.copy();

    if (y + 1 < height) bl = avgPixel(x, y + 1, numFrames, pixelBuffer);
    else bl = tl.copy();

    if (x + 1 < width && y + 1 < height) br = avgPixel(x + 1, y + 1, numFrames, pixelBuffer);
    else br = tl.copy();

    // Fill the scale * scale block of pixels
    for (int px = 0; px < scale; px++)
    {
      for (int py = 0; py < scale; py++)
      {
        float xFac = (float)px / scale; // 0-1 value from this pixel to the neighbour pixel
        float yFac = (float)py / scale; // (represents how much of each neighbour to take)

        Colour tColour = lerp(tl, tr, xFac); // Top colour
        Colour bColour = lerp(bl, br, xFac); // Bottom colour
        screenBuffer.set(x * scale + px, y * scale + py, lerp(tColour, bColour, yFac)); // lerp between them and set the screen buffer
      }
    }
  }

  // Gets the average of the pixels at (x,y) (buffer/downscaled pixels, not screen pixels)
  Colour avgPixel(int x, int y, int numFrames, Colour[] buffer)
  {
    for (int k = 0; k < numFrames; k++)
    {
      // frameIndex - 1 is most recent
      int frameNumber = getFrameNumber(-k - 1);

      buffer[k] = bufferedFrames[frameNumber].get(x, y);
    }

    return average(buffer);
  }

  // Just wraps the number around for you
  int getFrameNumber(int offset)
  {
    int raw = frameIndex + offset;
    while (raw < 0)
      raw += getNumFrames();
    while (raw >= getNumFrames())
      raw -= getNumFrames();
    return raw;
  }

  // Draws the given image to the screen at (x, y)
  void drawImage(int x, int y, Image image)
  {
    for (int i = 0; i < image.width; i++)
    {
      for (int j = 0; j < image.height; j++)
      {
        Colour col = image.get(i, j);
        color displayColour = color(col.r * 255, col.g * 255, col.b * 255); // Convert my Colour class to the 0-255 color object
        fill(displayColour);
        rect(x + i, y + j, 1, 1);

        // You can skip the clamp
        //col = col.copy();
        //col.clampValues();
        //color displayColour = color(saturate(col.r) * 255, saturate(col.g) * 255, saturate(col.b) * 255, 255);
      }
    }
  }
}
