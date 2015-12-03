      SUBROUTINE SMA2A
C
C     THIS SUBROUTINE FORMERLY GENERATED THE MGG AND BGG MATRICES FOR
C     THE SMA2 MODULE.  THESE OPERATIONS ARE NOW PERFORMED IN THE EMG
C     AND EMA MODULES AND SMA2A IS RETAINED IN SKELETAL FORM TO PROVIDE
C     A VEHICLE FOR USER-SUPPLIED ELEMENTS.
C
      LOGICAL          HEAT
      INTEGER          IZ(1),EOR,CLSRW,CLSNRW,FROWIC,SYSPRT,TNROWS,
     1                 OUTRW
      DOUBLE PRECISION DZ,DPWORD
      DIMENSION        INPVT(2),DZ(1),NAME(2)
      CHARACTER        UFM*23
      COMMON /XMSSG /  UFM
      COMMON /BLANK /  WTMASS,NOMGG,NOBGG,ICMAS,ICMBAR,ICMROD,ICMQD1,
     1                 ICMQD2,ICMTR1,ICMTR2,ICMTUB,ICMQDP,ICMTRP,ICMTRB
      COMMON /SMA2HT/  HEAT
      COMMON /SYSTEM/  ISYS,ISEW1(53),IPREC
      COMMON /SMA2IO/  IFCSTM,IFMPT,IFDIT,IDUM1,IFECPT,IGECPT,IFGPCT,
     1                 IGGPCT,IDUM2,IDUM3,IFMGG,IGMGG,IFBGG,IGBGG,IDUM4,
     2                 IDUM5,INRW,OUTRW,CLSNRW,CLSRW,NEOR,EOR,MCBMGG(7),
     3                 MCBBGG(7)
      COMMON /ZZZZZZ/  Z(1)
      COMMON /SMA2BK/  ICSTM,NCSTM,IGPCT,NGPCT,IPOINT,NPOINT,I6X6M,
     1                 N6X6M,I6X6B,N6X6B
      COMMON /SMA2CL/  IOPTB,BGGIND,NPVT,LLEFT,FROWIC,LROWIC,NROWSC,
     1                 TNROWS,JMAX,NLINKS,LINK(10),NOGO
      COMMON /GPTA1 /  NELEMS,LAST,INCR,NE(1)
      COMMON /SMA2ET/  ECPT(200)
      COMMON /ZBLPKX/  DPWORD,DUM(2),INDEX
      EQUIVALENCE      (Z(1),IZ(1),DZ(1))
      DATA    NAME  /  4HSMA2,4HA   /
C
      IPR = IPREC
C
C     READ THE FIRST TWO WORDS OF NEXT GPCT RECORD INTO INPVT(1).
C     INPVT(1) IS THE PIVOT POINT.  INPVT(1) .GT. 0 IMPLIES THE PIVOT
C     POINT IS A GRID POINT.  INPVT(1) .LT. 0 IMPLIES THE PIVOT POINT
C     IS A SCALAR POINT.  INPVT(2) IS THE NUMBER OF WORDS IN THE
C     REMAINDER OF THIS RECORD OF THE GPCT.
C
   10 CALL READ (*1000,*700,IFGPCT,INPVT(1),2,NEOR,IFLAG)
      NGPCT = INPVT(2)
      CALL READ (*1000,*3000,IFGPCT,IZ(IGPCT+1),NGPCT,EOR,IFLAG)
C
C     FROWIC IS THE FIRST ROW IN CORE. (1 .LE. FROWIC .LE. 6)
C
      FROWIC = 1
C
C     DECREMENT THE AMOUNT OF CORE REMAINING.
C
      LEFT = LLEFT - 2*NGPCT
      IF (LEFT .LE. 0) GO TO 3003
      IPOINT = IGPCT + NGPCT
      NPOINT = NGPCT
      I6X6M  = IPOINT + NPOINT
      I6X6M  = (I6X6M-1)/2 + 2
C
C     CONSTRUCT THE POINTER TABLE, WHICH WILL ENABLE SUBROUTINE INSERT
C     TO ADD THE ELEMENT MASS AND/OR DAMPING MATRICES TO MGG AND/OR BGG.
C
      IZ(IPOINT+1) = 1
      I1 = 1
      I  = IGPCT
      J  = IPOINT + 1
   30 I1 = I1 + 1
      IF (I1 .GT. NGPCT) GO TO 40
      I  = I + 1
      J  = J + 1
      INC = 6
      IF (IZ(I) .LT. 0) INC = 1
      IZ(J) = IZ(J-1) + INC
      GO TO 30
C
C     JMAX = THE NUMBER OF COLUMNS OF MGG THAT WILL BE GENERATED WITH
C     THE CURRENT GRID POINT.
C
   40 INC   = 5
      ILAST = IGPCT  + NGPCT
      JLAST = IPOINT + NPOINT
      IF (IZ(ILAST) .LT. 0) INC = 0
      JMAX = IZ(JLAST) + INC
C
C     TNROWS = THE TOTAL NUMBER OF ROWS OF THE MATRIX TO BE GENERATED
C              FOR THE CURRENT PIVOT POINT.
C     TNROWS = 6 IF THE CURRENT PIVOT POINT IS A GRID POINT.
C     TNROWS = 1 IF THE CURRENT PIVOT POINT IS A SCALAR POINT.
C
      TNROWS = 6
      IF (INPVT(1) .LT. 0) TNROWS = 1
C
C     IF 2*TNROWS*JMAX .LT. LEFT THERE ARE NO SPILL LOGIC PROBLEMS FOR
C     THE MGG SINCE THE WHOLE DOUBLE PRECISION SUBMATRIX OF ORDER
C     TNROWS*JMAX CAN FIT IN CORE.
C
      ITEMP = TNROWS*JMAX
      IF (2*ITEMP .LT. LEFT) GO TO 80
      CALL MESAGE (30,86,INPVT)
C
C     THE WHOLE MATRIX CANNOT FIT IN CORE, DETERMINE HOW MANY ROWS CAN
C     FIT. IF TNROWS = 1, WE CAN DO NOTHING FURTHER.
C
      IF (TNROWS .EQ. 1) GO TO 3003
      NROWSC = 3
   70 IF (2*NROWSC*JMAX .LT. LEFT) GO TO 90
      NROWSC = NROWSC - 1
      IF (NROWSC .EQ. 0) CALL MESAGE (-8,0,NAME)
      GO TO 70
   80 NROWSC = TNROWS
   90 FROWIC = 1
C
C     LROWIC IS THE LAST ROW IN CORE. (1 .LE. LROWIC .LE. 6)
C
      LROWIC = FROWIC + NROWSC - 1
C
C     ZERO OUT THE MGG SUBMATRIX IN CORE
C
  100 LOW = I6X6M + 1
      LIM = I6X6M + JMAX*NROWSC
      DO 115 I = LOW,LIM
  115 DZ(I) = 0.0D0
C
C     CHECK TO SEE IF BGG MATRIX IS DESIRED.
C
      IF (IOPTB .EQ. 0) GO TO 137
C
C     SINCE THE BGG MATRIX IS TO BE COMPUTED,DETERMINE WHETHER OR NOT IT
C     TOO CAN FIT IN CORE.
C
      IF (NROWSC .NE. TNROWS) GO TO 120
      IF (4*TNROWS*JMAX .LT. LEFT) GO TO 130
C
C     OPEN A SCRATCH FILE FOR BGG
C
  120 CALL MESAGE (-8,0,NAME)
C
C     THIS CODE TO BE FILLED IN LATER
C     ===============================
C
  130 I6X6B = I6X6M + JMAX*TNROWS
      LOW = I6X6B + 1
      LIM = I6X6B + JMAX*TNROWS
      DO 135 I = LOW,LIM
  135 DZ(I) = 0.0D0
C
C     INITIALIZE THE LINK VECTOR TO -1.
C
  137 DO 140 I = 1,NLINKS
  140 LINK(I) = -1
C
C     TURN FIRST PASS INDICATOR ON.
C
  150 IFIRST = 1
C
C     READ THE 1ST WORD OF THE ECPT RECORD, THE PIVOT POINT, INTO NPVT.
C
      CALL FREAD (IFECPT,NPVT,1,0)
C
C     READ THE NEXT ELEMENT TYPE INTO THE CELL ITYPE.
C
  160 CALL READ (*3025,*500,IFECPT,ITYPE,1,NEOR,IFLAG)
      IF (ITYPE.GE.53 .AND. ITYPE.LE.61) GO TO 165
      CALL PAGE2 (-3)
      SYSPRT = ISEW1(1)
      WRITE  (SYSPRT,161) UFM,ITYPE
  161 FORMAT (A23,' 2202, ELEMENT TYPE',I4,' NO LONGER SUPPORTED BY ',
     1       'SMA2 MODULE.', /5X,
     2       'USE EMG AND EMA MODULES FOR ELEMENT MATRIX GENERATION')
      NOGO = 1
      GO TO 1000
  165 CONTINUE
C
C     READ THE ECPT ENTRY FOR THE CURRENT TYPE INTO THE ECPT ARRAY. THE
C     NUMBER OF WORDS TO BE READ WILL BE NWORDS(ITYPE).
C
      IDX = (ITYPE-1)*INCR
      CALL FREAD (IFECPT,ECPT,NE(IDX+12),0)
      ITEMP = NE(IDX+23)
C
C     IF THIS IS THE 1ST ELEMENT READ ON THE CURRENT PASS OF THE ECPT
C     CHECK TO SEE IF THIS ELEMENT IS IN A LINK THAT HAS ALREADY BEEN
C     PROCESSED.
C
      IF (IFIRST .EQ. 1) GO TO 170
C
C     THIS IS NOT THE FIRST PASS.  IF ITYPE(TH) ELEMENT ROUTINE IS IN
C     CORE, PROCESS IT.
C
      IF (ITEMP .EQ. LINCOR) GO TO 180
C
C     THE ITYPE(TH) ELEMENT ROUTINE IS NOT IN CORE.  IF THIS ELEMENT
C     ROUTINE IS IN A LINK THAT ALREADY HAS BEEN PROCESSED READ THE NEXT
C     ELEMENT.
C
      IF (LINK(ITEMP) .EQ. 1) GO TO 160
C
C     SET A TO BE PROCESSED LATER FLAG FOR THE LINK IN WHICH THE ELEMENT
C     RESIDES
C
      LINK(ITEMP) = 0
      GO TO 160
C
C     SINCE THIS IS THE FIRST ELEMENT TYPE TO BE PROCESSED ON THIS PASS
C     OF THE ECPT RECORD, A CHECK MUST BE MADE TO SEE IF THIS ELEMENT
C     IS IN A LINK THAT HAS ALREADY BEEN PROCESSED.  IF IT IS SUCH AN
C     ELEMENT, WE KEEP IFIRST = 1 AND READ THE NEXT ELEMENT.
C
  170 IF (LINK(ITEMP) .EQ. 1) GO TO 160
C
C     SET THE CURRENT LINK IN CORE = ITEMP AND IFIRST = 0
C
      LINCOR = ITEMP
      IFIRST = 0
      ITYPX  = ITYPE - 52
C
C     CALL THE PROPER ELEMENT ROUTINE.
C
  180 GO TO (
C                                  CDUM1   CDUM2   CDUM3   CDUM4
C                                    53      54      55      56
     7                               4983,   4984,   4985,   4986,
C          CDUM5   CDUM6   CDUM7   CDUM8   CDUM9
C            57      58      59      60      61
     8     4987,   4988,   4989,   4990,   4991  ) , ITYPX
C
C
 4983 CALL MDUM1
      GO TO 160
 4984 CALL MDUM2
      GO TO 160
 4985 CALL MDUM3
      GO TO 160
 4986 CALL MDUM4
      GO TO 160
 4987 CALL MDUM5
      GO TO 160
 4988 CALL MDUM6
      GO TO 160
 4989 CALL MDUM7
      GO TO 160
 4990 CALL MDUM8
      GO TO 160
 4991 CALL MDUM9
      GO TO 160
C
C     AT STATEMENT NO. 500 WE HAVE HIT AN EOR ON THE ECPT FILE.  SEARCH
C     THE LINK VECTOR TO DETERMINE IF THERE ARE LINKS TO BE PROCESSED.
C
  500 LINK(LINCOR) = 1
      DO  510 I = 1,NLINKS
      IF (LINK(I) .EQ. 0) GO TO 520
  510 CONTINUE
      GO TO 525
C
C     SINCE AT LEAST ONE LINK HAS NOT BEEN PROCESSED THE ECPT FILE MUST
C     BE BACKSPACED.
C
  520 CALL BCKREC (IFECPT)
      GO TO 150
C
C     CHECK NOGO = 1 SKIP BLDPK
C
  525 IF (NOGO .EQ. 1) GO TO 10
C
C     AT THIS POINT BLDPK THE NUMBER OF ROWS IN CORE UNTO THE MGG FILE.
C
      ASSIGN 580 TO IRETRN
C
C     HEAT TRANSFER PROBLEM, SKIP MGG
C
      IF (HEAT) GO TO 580
C
      IFILE = IFMGG
      IMCB  = 1
C
C     MULTIPLY THE MASS MATRIX BY THE PARAMETER WTMASS IF IT IS NOT
C     UNITY
C
      IF (WTMASS .EQ. 1.0) GO TO 530
      LOW = I6X6M + 1
      LIM = I6X6M + JMAX*NROWSC
      DO 527 I = LOW,LIM
  527 DZ(I) = DZ(I)*WTMASS
  530 I1  = 0
  540 I2  = 0
      IBEG = I6X6M + I1*JMAX
      CALL BLDPK (2,IPR,IFILE,0,0)
  550 I2 = I2 + 1
      IF (I2 .GT. NGPCT) GO TO 570
      JJ = IGPCT + I2
      INDEX = IABS(IZ(JJ)) - 1
      LIM = 6
      IF (IZ(JJ) .LT. 0) LIM = 1
      JJJ = IPOINT + I2
      KKK = IBEG + IZ(JJJ) - 1
      I3 = 0
  560 I3 = I3 + 1
      IF (I3 .GT. LIM) GO TO 550
      INDEX = INDEX + 1
      KKK = KKK + 1
      DPWORD = DZ(KKK)
      IF (DPWORD .NE. 0.0D0) CALL ZBLPKI
      GO TO 560
  570 CALL BLDPKN (IFILE,0,MCBMGG(IMCB))
      I1 = I1 + 1
      IF (I1 .LT. NROWSC) GO TO 540
      GO TO IRETRN, (580,600)
C
C     IF THE BGG IS CALLED FOR BLDPK IT.
C
  580 IF (IOPTB .EQ.  0) GO TO 600
      IF (IOPTB .EQ. -1) GO TO 590
C
C     THE BGG MATRIX IS IN CORE
C
      ASSIGN 600 TO IRETRN
      I6X6M = I6X6B
      IFILE = IFBGG
      IMCB  = 8
      GO TO 530
C
C     HERE WE NEED LOGIC TO READ BGG FROM A SCRATCH FILE AND INSERT
C
  590 CONTINUE
C
C     TEST TO SEE IF THE LAST ROW IN CORE, LROWIC, = THE TOTAL NO. OF
C     ROWS TO BE COMPUTED, TNROWS.  IF IT IS, WE ARE DONE.  IF NOT, THE
C     ECPT MUST BE BACKSPACED.
C
  600 IF (LROWIC .EQ. TNROWS) GO TO 10
      CALL BCKREC (IFECPT)
      FROWIC = FROWIC + NROWSC
      LROWIC = LROWIC + NROWSC
      GO TO 100
C
C     CHECK NOGO = 1 SKIP BLDPK
C
  700 IF (NOGO .EQ. 1) GO TO 10
C
C     HERE WE HAVE A PIVOT POINT WITH NO ELEMENTS CONNECTED, SO THAT
C     NULL COLUMNS MUST BE OUTPUT ON THE MGG AND BGG FILES.
C
      LIM = 6
      IF (INPVT(1) .LT. 0) LIM = 1
      DO 710 I = 1,LIM
      IF (HEAT) GO TO 705
      CALL BLDPK (2,IPR,IFMGG,0,0)
      CALL BLDPKN (IFMGG,0,MCBMGG)
  705 IF (IOPTB .NE. 1) GO TO 710
      CALL BLDPK (2,IPR,IFBGG,0,0)
      CALL BLDPKN (IFBGG,0,MCBBGG)
  710 CONTINUE
      CALL SKPREC (IFECPT,1)
      GO TO 10
C
C     RETURN SINCE AN EOF HAS BEEN HIT ON THE GPCT FILE
C
 1000 IF (NOGO .EQ.1) CALL MESAGE (-61,0,NAME)
      RETURN
C
C     ERROR RETURNS
C
 3000 IFILE = IFGPCT
      IPARM = 3
      GO TO 4010
 3003 CALL MESAGE (-8,IFILE,NAME)
 3025 IFILE = IFECPT
      IPARM = 2
 4010 CALL MESAGE (-IPARM,IFILE,NAME)
      CALL MESAGE (-30,87,ITYPE)
      RETURN
C
      END