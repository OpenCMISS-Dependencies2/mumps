C
C  This file is part of MUMPS 5.6.0, released
C  on Wed Apr 19 15:50:57 UTC 2023
C
C
C  Copyright 1991-2023 CERFACS, CNRS, ENS Lyon, INP Toulouse, Inria,
C  Mumps Technologies, University of Bordeaux.
C
C  This version of MUMPS is provided to you free of charge. It is
C  released under the CeCILL-C license 
C  (see doc/CeCILL-C_V1-en.txt, doc/CeCILL-C_V1-fr.txt, and
C  https://cecill.info/licences/Licence_CeCILL-C_V1-en.html)
C
      SUBROUTINE MUMPS_GET_INT_DBL_SIZES( IS, DS )
      INTEGER IS, DS
#if defined(t3e)
      IS = 8
      DS = 16
#else
      IS = 4
      DS = 8
#endif
      END SUBROUTINE MUMPS_GET_INT_DBL_SIZES
