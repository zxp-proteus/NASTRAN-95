      SUBROUTINE MMA302 ( ZI, ZD )
C
C     MMA302 PERFORMS THE MATRIX OPERATION USING METHOD 30 AND 
C       REAL DOUBLE PRECISION
C
C       (+/-)A(T & NT) * B (+/-)C = D
C     
C     MMA302 USES METHOD 30 WHICH IS AS FOLLOWS:
C       1.  THIS IS FOR "A" NON-TRANSPOSED AND TRANSPOSED
C       2.  CALL 'MMARM1' TO PACK AS MANY COLUMNS OF "A" INTO MEMORY 
C           AS POSSIBLE LEAVING SPACE FOR ONE COLUMN OF "B" AND "D".
C       3.  INITIALIZE EACH COLUMN OF "D" WITH THE DATA FROM "C".
C       4.  USE UNPACK TO READ MATRICES "B" AND "C".
C
      INTEGER           ZI(2)      ,T
      INTEGER           TYPEI      ,TYPEP    ,TYPEU ,SIGNAB, SIGNC
      INTEGER           RD         ,RDREW    ,WRT   ,WRTREW, CLSREW,CLS
      INTEGER           OFILE      ,FILEA    ,FILEB ,FILEC , FILED
      DOUBLE PRECISION  ZD(2)      ,DTEMP
      INCLUDE           'MMACOM.COM'
      COMMON / NAMES  / RD         ,RDREW    ,WRT   ,WRTREW, CLSREW,CLS
      COMMON / TYPE   / IPRC(2)    ,NWORDS(4),IRC(4)
      COMMON / MPYADX / FILEA(7)   ,FILEB(7) ,FILEC(7)    
     1,                 FILED(7)   ,NZ       ,T     ,SIGNAB,SIGNC ,PREC1 
     2,                 SCRTCH     ,TIME
      COMMON / SYSTEM / KSYSTM(152)
      COMMON / UNPAKX / TYPEU      ,IUROW1   ,IUROWN, INCRU
      COMMON / PACKX  / TYPEI      ,TYPEP    ,IPROW1, IPROWN , INCRP
      EQUIVALENCE       (KSYSTM( 1),SYSBUF)  , (KSYSTM( 2),IWR   ) 
      EQUIVALENCE       (FILEA(2)  ,NAC   )  , (FILEA(3)  ,NAR   )
     1,                 (FILEA(4)  ,NAFORM)  , (FILEA(5)  ,NATYPE)
     2,                 (FILEA(6)  ,NANZWD)  , (FILEA(7)  ,NADENS)
      EQUIVALENCE       (FILEB(2)  ,NBC   )  , (FILEB(3)  ,NBR   )
     1,                 (FILEB(4)  ,NBFORM)  , (FILEB(5)  ,NBTYPE)
     2,                 (FILEB(6)  ,NBNZWD)  , (FILEB(7)  ,NBDENS)
      EQUIVALENCE       (FILEC(2)  ,NCC   )  , (FILEC(3)  ,NCR   )
     1,                 (FILEC(4)  ,NCFORM)  , (FILEC(5)  ,NCTYPE)
     2,                 (FILEC(6)  ,NCNZWD)  , (FILEC(7)  ,NCDENS)
      EQUIVALENCE       (FILED(2)  ,NDC   )  , (FILED(3)  ,NDR   )
     1,                 (FILED(4)  ,NDFORM)  , (FILED(5)  ,NDTYPE)
     2,                 (FILED(6)  ,NDNZWD)  , (FILED(7)  ,NDDENS)
C
C
C   OPEN CORE ALLOCATION AS FOLLOWS:
C     Z( 1        ) = ARRAY FOR ONE COLUMN OF "B" MATRIX
C     Z( IDX      ) = ARRAY FOR ONE COLUMN OF "D" MATRIX
C     Z( IAX      ) = ARRAY FOR MULTIPLE COLUMNS OF "A" MATRIX
C        THROUGH
C     Z( LASMEM   )
C     Z( IBUF4    ) = BUFFER FOR "D" FILE
C     Z( IBUF3    ) = BUFFER FOR "C" FILE
C     Z( IBUF2    ) = BUFFER FOR "B" FILE 
C     Z( IBUF1    ) = BUFFER FOR "A" FILE
C     Z( NZ       ) = END OF OPEN CORE THAT IS AVAILABLE
C
C PROCESS ALL OF THE COLUMNS OF "B";  ADD "C" DATA ON FIRST PASS
      DO 60000 II = 1, NBC
C      PRINT *,' PROCESSING B MATRIX COLUMN II=',II
      IUROW1 = -1
      TYPEU  = NDTYPE 
      CALL UNPACK ( *930, FILEB, ZD( 1 ) )
      IROWB1 = IUROW1
      IROWBN = IUROWN
      GO TO 940
930   IROWB1 = 0
      IROWBN = 0
      IF ( IFILE .NE. 0 ) GO TO 940
      IPROWN = 1
      CALL PACK ( 0.0D0, OFILE, FILED )
      IPROWN = NDR
      GO TO 60000
940   CONTINUE
      IF ( IFILE .EQ. 0 ) GO TO 950            
      IUROW1 = 1
      IUROWN = NDR
      TYPEU  = NDTYPE 
      IF ( IPASS .EQ. 1 ) TYPEU = NDTYPE * SIGNC
      CALL UNPACK (*950, IFILE, ZD( IDX2+1 ) )
      GO TO 980
950   CONTINUE
      DO 970 J = 1, NDR
      ZD( IDX2+J ) = 0
970   CONTINUE
980   CONTINUE
C
C CHECK IF COLUMN OF "B" IS NULL
C
      INDXA  = IAX
      IF ( IROWB1 .EQ. 0 ) GO TO 50000
      IF ( T .NE. 0 ) GO TO 5000
C      
C "A" NON-TRANSPOSE CASE    ( A * B  +  C )      
C
C DOUBLE PRECISION
1000  CONTINUE
      DO 1500 I = 1, NCOLPP
      INDXAL = ZI( INDXA+1 ) + IAX - 1
      ICOLA  = IBROW+I
      IF ( ICOLA .LT. IROWB1 .OR. ICOLA .GT. IROWBN ) GO TO 1450
      IBROWI = ICOLA - IROWB1 + 1
      DTEMP  = ZD( IBROWI )
      IF ( DTEMP .EQ. 0.0D0 ) GO TO 1450
      IF ( ICOLA .NE. IABS( ZI( INDXA ) ) ) GO TO 70001
      INDXA  = INDXA+2
1100  CONTINUE
      IF ( INDXA .GE. INDXAL ) GO TO 1450
      IROWA1 = ZI( INDXA )
      NTMS   = ZI( INDXA+1 )
      IROWAN = IROWA1 + NTMS - 1
      INDXAV = ( ( INDXA+3 ) / 2 ) - IROWA1
      DO 1400 K = IROWA1, IROWAN
C
C         D = C + A*B
C      
C      PRINT *,' K,D,A,B=',K,ZD(IDX2+K),ZD(INDXAV+K),ZD(IBROWI)
      ZD( IDX2+K ) = ZD( IDX2+K ) +  ZD( INDXAV+K ) * DTEMP
1400  CONTINUE
      INDXA  = INDXA + 2 + NTMS*2
      GO TO 1100
1450  INDXA  = INDXAL
1500  CONTINUE
      GO TO 50000
C
C  TRANSPOSE CASE ( A(T) * B + C )
C
5000  CONTINUE      
C DOUBLE PRECISION
10000 CONTINUE
      INDXB  = 1 - IROWB1
      IDXX   = IDX2 + IBROW 
      DO 15000 I = 1, NCOLPP
      ICOLA  = IBROW + I 
      IF ( ICOLA .NE. IABS( ZI( INDXA ) ) ) GO TO 70001
      INDXAL = ZI( INDXA+1 ) + IAX - 1
      INDXA  = INDXA+2
11000 CONTINUE
      IF ( INDXA .GE. INDXAL ) GO TO 14500
      IROWA1 = ZI( INDXA )
      NTMS   = ZI( INDXA+1 )
      IROWAN = IROWA1 + NTMS - 1
      IROW1  = MAX0( IROWA1, IROWB1 )
      IROWN  = MIN0( IROWAN, IROWBN )
      IF ( IROWN .LT. IROW1 ) GO TO 14100
      INDXAV = ( ( INDXA + 3 ) / 2 ) - IROWA1
C
C         D = C + A*B
C      
      DTEMP = 0.0
      DO 14000 K = IROW1, IROWN
      DTEMP = DTEMP +  ZD( INDXAV+K ) * ZD( INDXB+K ) 
14000 CONTINUE
      ZD( IDXX+I ) = ZD( IDXX+I ) +  DTEMP 
14100 CONTINUE
      INDXA  = INDXA + 2 + NTMS*2
      GO TO 11000
14500 INDXA  = INDXAL
15000 CONTINUE
      GO TO 50000
C END OF PROCESSING THIS COLUMN FOR THIS PASS
50000 CONTINUE
C  NOW SAVE COLUMN 
      CALL PACK ( ZD( IDX2+1 ), OFILE, FILED )
60000 CONTINUE
      GO TO 70000
70001 CONTINUE
      WRITE ( IWR, 90001 ) ICOLA, ZI( INDXA ), IAX, INDXA
90001 FORMAT(' UNEXPECTED COLUMN FOUND IN PROCESSING MATRIX A'
     &,/,' COLUMN EXPECTED:',I6
     &,/,' COLUMN FOUND   :',I6
     &,/,' IAX =',I7,'  INDXA=',I7 )
      CALL MESAGE ( -61, 0, 0 )
70000 RETURN
      END

