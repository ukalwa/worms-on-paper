# Software to track worms *(C. Elegans)* on Paper and analyse their behavior at different drug concentrations

This software is written for our paper in *APL Bioengineering*:
*"Flexible and disposable paper and plastic-based gel micropads for nematode handling, imaging and chemical testing"*

Requirments
===========

*Environment Setup*

-   Download & Install [Matlab R2016a]
-   Install Image Processing Toolbox

It was tested on Windows 10 and Mac OS X.

Usage
=====

To start, please run `Matlab/uPAD_tracker_plastic.m`

Steps involved
==============
This script loads the video file selected by the user and performs 
following operations:

    1)  Creates a video file for adding tracking information to the
        original video.
    2)  Using a Circular Hough Transform (CHT), it selects the
        circular uPADs in the frames.
    3)  Applies an Active Contour algorithm on the detected uPADs to
        refine the edges and handle worm detection even when the animals are touching the edges of uPADs.
    4)  Removes the background from the frame by applying a local
        thresholding technique with a window size of 100 x 100 pixels 
        and a threshold value of 90%.
    5)  Identifies worms by characterization parameters defined for 
        L4-stage C. elegans and ouputs the centroid information to separate excel files.
    6)  Repeats steps 2 through 5 for every frame in the video.
    7)  Saves the tracking video and excel files to the hard disk.


License
=======

This code is GNU GENERAL PUBLIC LICENSED.


Acknowledgements
================
meanthresh.m is written by Jan Motl and can be found at [meanthresh] 

Contributing
============

If you have any suggestions or identified bugs please feel free to post
them!

  [Matlab]: https://www.mathworks.com/downloads/
  [meanthresh]: https://www.mathworks.com/matlabcentral/fileexchange/41787-meanthresh-local-image-thresholding?focused=3783566&tab=function 
