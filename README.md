A description of the EMC Verification System (EVS) will go here. 
The branch of feature/evsretro preserve the structure of running both AQM v6 and v7 output, as well as aqmv7sp getting data from user archive directory similar to v6 directory structure..

NCO does not allow EVSv1.0 to have the code/scripts handling AQMv7 output.  Thus, the PR#204 aqm restart, all *v6* files has been rename to no-version_number file and used in EVSiv1.0.  All *v7* files has been removed.

This branch will never MERGE with develop beginning with PR#204, so developer can maintaining it ability for handling AQMv6 and AQMV7 output for AQMv7 implementation.
