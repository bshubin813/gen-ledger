      *---------------------------------------------------------------------------------------------
      * BattleShip/400
      *
      *---------------------------------------------------------------------------------------------

     H DFTACTGRP(*NO) ACTGRP(*CALLER)

     FBattleDF  cf   e             workstn infds(dsinf)

      *-- Define command keys
     D dsinf           ds
     D fkey                           1    overlay(dsinf:369)
     D  f03            c                   const(X'33')
     D  f05            c                   const(X'35')
     D  f10            c                   const(X'3A')
     D  f12            c                   const(X'3C')
      *
     D Row             s              3u 0                                      Row
     D Col             s              3u 0                                      Column
     D GridDS        e ds                  extname(BattlePF) inz
     D pointer         s               *   inz(%addr(r01c01))                   attack screen fields
     D pointer2        s               *   inz(%addr(atr0101))                  attack attrib array
     D pointer3        s               *   inz(%addr(b01c01))                   defend screen flds
     D pointer4        s               *   inz(%addr(btr0101))                  defend attrib array
     D pointer5        s               *   inz(%addr(srow1))                    deployment row
     D pointer6        s               *   inz(%addr(scol1))                    deployment col
     D pointer7        s               *   inz(%addr(sdir1))                    deployment direction
     D GridA           s              1    dim(100)  based(pointer)
     D AttrAttk        s              1    dim(100)  based(pointer2)
     D GridD           s              1    dim(100)  based(pointer3)
     D AttrDefd        s              1    dim(100)  based(pointer4)
     D srow            s              3  0 dim(5)    based(pointer5)
     D scol            s              3  0 dim(5)    based(pointer6)
     D sdir            s              1    dim(5)    based(pointer7)
     D GridC           s              1    dim(100)                             computer Defend Grid
     D GridW           s              1    dim(100)                             work Grid
     D GridDSave       s              1    dim(100)                             save for sunk locate
     D Hash            s              3u 0 dim(100)                             hash count
     D WhereHit1       s              3u 0                                       where hit
     D WhereHit2       s              3u 0                                       where hit
     D alpha1          s              1
     D X               s              3u 0
     D Y               s              3u 0
     D SS              s              3u 0
     D ShipSize        s              3u 0
     D HitFlg          s              1    inz(*off)
     D CollisionFlag   s              1
     D DeployedFlg     s              1
      *
     D                 ds
     D HHH                          100
     D OverlayHHH                     1    dim(100)  overlay(hhh)
      *
     D TimesHit2       s              3u 0
     D TimesHit3       s              3u 0
     D TimesHit4       s              3u 0
     D TimesHit5       s              3u 0
     D UserxHit2       s              3u 0
     D UserxHit3       s              3u 0
     D UserxHit4       s              3u 0
     D UserxHit5       s              3u 0
      *
      *---------------------------------------------------------------------------------------------
      * Functions to check availability of next contiguous coordinate
      *---------------------------------------------------------------------------------------------
      *
     D UPone           pr             3u 0
     D                                3u 0
     D                              100
     D                                3    const
      *   -----------------------------------------------------
     D DOWNone         pr             3u 0
     D                                3u 0
     D                              100
     D                                3    const
      *   -----------------------------------------------------
     D LEFTone         pr             3u 0
     D                                3u 0
     D                              100
     D                                3    const
      *   -----------------------------------------------------
     D RIGHTone        pr             3u 0
     D                                3u 0
     D                              100
     D                                3    const
      *
      *   -----------------------------------------------------
      *return row and column from a single index value
     D getrow          pr             3u 0
     D                                3u 0 const
      *   -----------------------------------------------------
     D getcol          pr             3u 0
     D                                3u 0 const
      *
      *   -----------------------------------------------------
      *get single level index from row,column coordinates
     D getx            pr             3u 0
     D                                3u 0 const
     D                                3u 0 const
      *
      *   -----------------------------------------------------
      *get cursor row and column
     D QsnGetCsrAdr    PR            10I 0 extproc('QsnGetCsrAdr')              get cursor row,colum
     D QsnCursorRow                  10i 0 const
     D QsnCursorColum                10i 0 const
     D QsnLowLevelHan                10i 0 const
     Db                                    like(vApiErrDS)                      error parm
      *
      *   -----------------------------------------------------
     D getRandom       pr             3u 0
     D                                3u 0 const                                upper limit value
      *
      *   -----------------------------------------------------
     D  randVector     s              3u 0
     D  randIndex      s              3u 0
     D  sizecount      s              3u 0
      *   -----------------------------------------------------
     D vApiErrDs       ds
     D  vbytpv                       10i 0 inz(%size(vApiErrDs))                bytes provided
     D  vbytav                       10i 0 inz(0)                               bytes returned
     D  vmsgid                        7a                                        error msgid
     D  vresvd                        1a                                        reserved
     D  vrpldta                      50a                                        replacement data
     D QsnCursorRow    s             10i 0
     D QsnCursorCol    s             10i 0
      *
      *   ------------------------------------------------------------------------------------------
     C                   exsr      setUserShp
     C                   exsr      setComputerShp
     C                   eval      csrrow = 5                                   LINE NUMBER
     C                   eval      csrcol = 7                                   COLUMN NUMBER
      *
 1B  C                   dou       1=2
     C                   exfmt     screen2
      *
      *  get cursor row and column
     C                   callp     QsnGetCsrAdr(
     C                             QsnCursorRow:
     C                             QsnCursorCol:
     C                             0:vApiErrDs)
     C                   eval      csrrow=QsnCursorRow                          LINE NUMBER
     C                   eval      csrcol=QsnCursorCol                          COLUMN NUMBER
      * F5=Restart
 2B  C                   if        fkey=f05                                     refresh
     C                   eval      csrrow = 5
     C                   eval      csrcol = 7
     C                   clear                   GridA
     C                   clear                   GridC
     C                   clear                   AttrAttk
     C                   clear                   AttrDefd
     C                   clear                   TimesHit2
     C                   clear                   TimesHit3
     C                   clear                   TimesHit4
     C                   clear                   TimesHit5
     C                   clear                   UserxHit2
     C                   clear                   UserxHit3
     C                   clear                   UserxHit4
     C                   clear                   UserxHit5
     C                   clear                   Udspatr2
     C                   clear                   Udspatr3
     C                   clear                   Udspatr4
     C                   clear                   Udspatr5
     C                   clear                   edspatr2
     C                   clear                   edspatr3
     C                   clear                   edspatr4
     C                   clear                   edspatr5
     C                   eval      *in22=*off
     C                   eval      *in23=*off
     C                   exsr      setUserShp
     C                   exsr      setComputerShp
 1I  C                   iter
 2E  C                   endif
      *
 2B  C                   if        fkey=f03                                     F3=exit
     C                             or fkey=f12                                  F12=cancel
 1L  C                   leave
 2E  C                   endif
      *
      * --------------------------------------------------------------------------------------------
      * Process the users attack then let the computer have a shot at it!
      * --------------------------------------------------------------------------------------------
      *
     C                   exsr      UserAttack                                   user X
     C                   exsr      ComputerAttack                               computer X
      *
 1E  C                   enddo
     C                   eval      *inlr=*on
     C                   return
      *
      * --------------------------------------------------------------------------------------------
      * Spin through the array looking for attacks.
      * --------------------------------------------------------------------------------------------
      *
     C     UserAttack    begsr
 1B  C                   for       x=1 to 100
 2B  C                   if        GridA(x)='X'
 3B  C                   if        GridC(x) = ' '
     C                   eval      GridA(x)='.'
     C                   eval      AttrAttk(x)= x'BA'                           blue/protect
 3X  C                   else
      *
 4B  C                   select
 4X  C                   when      GridC(x)='2'
     C                   eval      UserxHit2 = UserxHit2 + 1
 4X  C                   when      GridC(x)='3'
     C                   eval      UserxHit3 = UserxHit3 + 1
 4X  C                   when      GridC(x)='4'
     C                   eval      UserxHit4 = UserxHit4 + 1
 4X  C                   when      GridC(x)='5'
     C                   eval      UserxHit5 = UserxHit5 + 1
 4E  C                   endsl
      *
 4B  C                   select
 4X  C                   when      UserxHit2=2
     C                   eval      edspatr2=x'A8'
 5B  C                   for       y=1 to 100
 6B  C                   if        GridC(y)='2'
     C                   eval      GridA(y)='S'
     C                   eval      AttrAttk(y)=x'A9'
 6E  C                   endif
 5E  C                   endfor
     C                   eval      UserxHit2=9
      *
 4X  C                   when      UserxHit3=3
     C                   eval      edspatr3=x'A8'
 5B  C                   for       y=1 to 100
 6B  C                   if        GridC(y)='3'
     C                   eval      GridA(y)='S'
     C                   eval      AttrAttk(y)=x'A9'
 6E  C                   endif
 5E  C                   endfor
     C                   eval      UserxHit3=9
      *
 4X  C                   when      UserxHit4=4
     C                   eval      edspatr4=x'A8'
 5B  C                   for       y=1 to 100
 6B  C                   if        GridC(y)='4'
     C                   eval      GridA(y)='S'
     C                   eval      AttrAttk(y)=x'A9'
 6E  C                   endif
 5E  C                   endfor
     C                   eval      UserxHit4=9
      *
 4X  C                   when      UserxHit5=5
     C                   eval      edspatr5=x'A8'
 5B  C                   for       y=1 to 100
 6B  C                   if        GridC(y)='5'
     C                   eval      GridA(y)='S'
     C                   eval      AttrAttk(y)=x'A9'
 6E  C                   endif
 5E  C                   endfor
     C                   eval      UserxHit5=9
      *
 4X  C                   other
     C                   eval      GridA(x)='H'
     C                   eval      AttrAttk(x)=x'B3'                            reverse yellow
 4E  C                   endsl
 3E  C                   endif
 2E  C                   endif
 1E  C                   endfor
      *
      *        -------------------------------------------------------------------------------------
      *        Check and see if ALL enemy ships are sunk.
      *        -------------------------------------------------------------------------------------
 1B  C                   if        UserxHit2 = 9 and
     C                             UserxHit3 = 9 and
     C                             UserxHit4 = 9 and
     C                             UserxHit5 = 9
     C                   eval      *in22=*on
 1E  C                   endif
     C                   endsr
      *
      * --------------------------------------------------------------------------------------------
      * Blow the users stuff outta the water!!
      * The computer is going to fire at random, until it gets a hit..The random part
      * will use a hash table function to only select randomly from the remaining open spaces.
      *
      *  The computer will spin down the users defend array looking for a place it has already
      *  gotten a hit.   When it find ones, check all adjacent row/columns for un hit space
      *  If one is found,  FIRE ONE!  If no hits are found or all adjacent places or filled,
      *  continue with hash table random
      *  Three different types of activity.
      *  1. Multiple Hits detected.
      *  2. Single Hit Detected.
      *  3. No hits detected.
      * --------------------------------------------------------------------------------------------
     C     ComputerAttackBegsr
     C                   clear                   WhereHit1
     C                   clear                   WhereHit2
     C                   eval      *in81=*off
     C                   eval      HitFlg = *off
     C                   eval      OverlayHHH = GridD
      *
     C                   eval      WhereHit1=%scan('H':hhh)
 1B  C                   if        WhereHit1>0
     C                   eval      *in81=*on
 2B  C                   if        WhereHit1<100
     C                   eval      WhereHit2=%scan('H':hhh:WhereHit1+1)
 2E  C                   endif
 1E  C                   endif
      *
      *    -----------------------------------------------------------------------------------------
      *    MULTIPLE HITS.
      *    -----------------------------------------------------------------------------------------
 1B  C                   select
 1X  C                   when      *in81=*on and
     C                             WhereHit2>0
      *
      *       --------------------------------------------------------------------------------------
      *       Run left down the hits first
      *       --------------------------------------------------------------------------------------
 2B  C                   if        getrow(WhereHit1) = getrow(WhereHit2)        SAME ROW
     C                   eval      x=WhereHit1
 3B  C                   dou       x=125                                        all processed
     C                   eval      X = LEFTone(x:HHH:'MLT')                      see if left  OK
 4B  C                   if        x<101                                         Nuke that coordinat
     C                             and GridD(x) <> 'H'
     C                   exsr      DropBombOnX
     C                   eval      HitFlg = *on
 3L  C                   leave
 4E  C                   endif
 3E  C                   enddo
      *
      *       --------------------------------------------------------------------------------------
      *       Run right down the hits if one to left not found
      *       --------------------------------------------------------------------------------------
 3B  C                   if        HitFlg=*off                                  no hits to left
     C                   eval      x=WhereHit1
 4B  C                   dou       x=125                                        all processed
     C                   eval      X = RIGHTone(x:HHH:'MLT')                      see if left  OK
 5B  C                   if        x<101                                         Nuke that coordinat
     C                             and GridD(x) <> 'H'
     C                   exsr      DropBombOnX
     C                   eval      HitFlg = *on
 4L  C                   leave
 5E  C                   endif
 4E  C                   enddo
 3E  C                   endif
 2E  C                   endif
      *
      *       --------------------------------------------------------------------------------------
      *       Run UP the hits
      *
      *          Special condition to the hit algorithm.  If there are two different boats side
      *          by side.     23   and we get a hit here 23  The computer winds up with   23
      *                       23                         H3                              mHHm
      *                        3                          3                                3
      *          The computers take the first hit found and runs up or down that boat till sunk.
      *       --------------------------------------------------------------------------------------
 2B  C                   if        getcol(WhereHit1) = getcol(WhereHit2)        SAME COLUMN
     C                             or hitflg=*off                               side by side boats
     C                   eval      x=WhereHit1
 3B  C                   dou       x=125                                         all processed
     C                   eval      X = UPone(x:HHH:'MLT')                        see if up OK
 4B  C                   if        x<101                                         Nuke that coordinat
     C                             and GridD(x) <> 'H'
     C                   exsr      DropBombOnX
     C                   eval      HitFlg = *on
 3L  C                   leave
 4E  C                   endif
 3E  C                   enddo
      *
      *       --------------------------------------------------------------------------------------
      *       Run DOWN the hits if one to left not found
      *       --------------------------------------------------------------------------------------
 3B  C                   if        HitFlg=*off                                  no hits to left

     C                   eval      x=WhereHit1
 4B  C                   dou       x=125                                        all processed
     C                   eval      X = DOWNone(x:HHH:'MLT')                      see if left  OK
 5B  C                   if        x<101                                         Nuke that coordinat
     C                             and GridD(x) <> 'H'
     C                   exsr      DropBombOnX
     C                   eval      HitFlg = *on
 4L  C                   leave
 5E  C                   endif
 4E  C                   enddo
 3E  C                   endif
 2E  C                   endif
      *
      *    -----------------------------------------------------------------------------------------
      *    FOUND A SINGLE HIT.
      *    Drop a bomb on the first available contiguous grid location.
      *    -----------------------------------------------------------------------------------------
 1X  C                   when      *in81=*on and
     C                             WhereHit2=0
     C                   eval      X = LEFTone(WhereHit1:HHH:'SGL')             see if left  OK
 2B  C                   if        x<105                                         Nuke that coordinat
     C                   exsr      DropBombOnX
 2X  C                   else
     C                   eval      X = RIGHTone(WhereHit1:HHH:'SGL')            see if right OK
 3B  C                   if        x<105
     C                   exsr      DropBombOnX
 3X  C                   else
     C                   eval      X = UPone(WhereHit1:HHH:'SGL')               see if up    OK
 4B  C                   if        x<105
     C                   exsr      DropBombOnX
 4X  C                   else
     C                   eval      X = DOWNone(WhereHit1:HHH:'SGL')             see if down  OK
 5B  C                   if        x<105
     C                   exsr      DropBombOnX
 5E  C                   endif
 4E  C                   endif
 3E  C                   endif
 2E  C                   endif
      *
      *   ------------------------------------------------------------------------------------------
      *   If couldn't find a place for a good hit,
      *   Load a hash table with all indexes that are not already Hit or missed.  Execute a random
      *   function with upper limit as count of available indexes.  Use the random value
      *   to access the hash table entry contain the index to be targeted.
      *
      *   To increase efficiency,  search random hits in a grid fashion..  We will use a
      *   method that says skip row+col=odd number.
      *   ------------------------------------------------------------------------------------------
 1X  C                   other
     C                   clear                   hash
     C                   clear                   y
      *
 2B  C                   for       x=1 to 100
 3B  C                   If        GridD(x)='m' or
     C                             GridD(x)='H' or
     C                             GridD(x)='S'
 3X  C                   else
 4B  C                   if        %rem(getrow(x) + getcol(x):2)=0
     C                   eval      y=y+1
     C                   eval      Hash(y)=x
 4E  C                   endif
 3E  C                   endif
 2E  C                   endfor
      *
 2B  C                   if        y>0
     C                   eval      x=hash(GetRandom(y))
     C                   exsr      DropBombOnX
 2E  C                   endif
 1E  C                   endsl
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      * Unload the BOMB!!!
      *---------------------------------------------------------------------------------------------
     C     DropBombOnX   begsr
 1B  C                   if        GridD(x)='.'
     C                   eval      GridD(x)='m'                                 missed
     C                   eval      AttrDefd(x)=x'BB'
 1X  C                   else
      *
 2B  C                   select
 2X  C                   when      GridD(x)='2'
     C                   eval      udspatr2=x'B3'
     C                   eval      TimesHit2 = TimesHit2  + 1
 2X  C                   when      GridD(x)='3'
     C                   eval      udspatr3=x'B3'
     C                   eval      TimesHit3 = TimesHit3 + 1
 2X  C                   when      GridD(x)='4'
     C                   eval      udspatr4=x'B3'
     C                   eval      TimesHit4 = TimesHit4 + 1
 2X  C                   when      GridD(x)='5'
     C                   eval      udspatr5=x'B3'
     C                   eval      TimesHit5 = TimesHit5 + 1
 2E  C                   endsl
      *
 2B  C                   select
 2X  C                   when      TimesHit2=2
     C                   eval      udspatr2=x'A8'
 3B  C                   for       x=1 to 100
 4B  C                   if        Griddsave(x)='2'
     C                   eval      GridD(x)='S'
     C                   eval      AttrDefd(x)=x'A9'
 4E  C                   endif
 3E  C                   endfor
     C                   eval      TimesHit2=9
      *
 2X  C                   when      TimesHit3=3
     C                   eval      udspatr3=x'A8'
 3B  C                   for       x=1 to 100
 4B  C                   if        Griddsave(x)='3'
     C                   eval      GridD(x)='S'
     C                   eval      AttrDefd(x)=x'A9'
 4E  C                   endif
 3E  C                   endfor
     C                   eval      TimesHit3=9
      *
 2X  C                   when      TimesHit4=4
     C                   eval      udspatr4=x'A8'
 3B  C                   for       x=1 to 100
 4B  C                   if        Griddsave(x)='4'
     C                   eval      GridD(x)='S'
     C                   eval      AttrDefd(x)=x'A9'
 4E  C                   endif
 3E  C                   endfor
     C                   eval      TimesHit4=9
      *
 2X  C                   when      TimesHit5=5
     C                   eval      udspatr5=x'A8'
 3B  C                   for       x=1 to 100
 4B  C                   if        Griddsave(x)='5'
     C                   eval      GridD(x)='S'
     C                   eval      AttrDefd(x)=x'A9'
 4E  C                   endif
 3E  C                   endfor
     C                   eval      TimesHit5=9
      *
 2X  C                   other
     C                   eval      GridD(x)='H'                                 hit
     C                   eval      AttrDefd(x)=x'A9'
 2E  C                   endsl
 1E  C                   endif
      *
      *        -------------------------------------------------------------------------------------
      *        Check and see if ALL user ships are sunk.  set loser indicator and show
      *        where remaining computer ships are locationed.
      *        -------------------------------------------------------------------------------------
 1B  C                   if        TimesHit2 = 9 and
     C                             TimesHit3 = 9 and
     C                             TimesHit4 = 9 and
     C                             TimesHit5 = 9
     C                   eval      *in23=*on
 2B  C                   for       x=1 to 100
 3B  C                   if        grida(x)=' '
     C                   eval      grida(x)=gridc(x)
 3E  C                   endif
 2E  C                   endfor
 1E  C                   endif
     C                   endsr
      *
      * --------------------------------------------------------------------------------------------
      * All user to set up their ship locations.
      * --------------------------------------------------------------------------------------------
     C     setUserShp    begsr
     C                   eval      *in10=*off
     C                   eval      GridD='.'
     C                   eval      AttrDefd= x'BA'
      *
 1B  C                   dou       1=2
     C                   exfmt     screen1
 2B  C                   if        fkey=f03                                     F3=exit
     C                             or fkey=f12                                  F12=cancel
     C                   eval      *inlr=*on
     C                   return
 2E  C                   endif
     C                   eval      *in10=*off
      *
      *     ----------------------------------------------------------------------------------------
      *     Let the computer generate the Grid.
      *     ----------------------------------------------------------------------------------------
 2B  C                   if        fkey=f05                                     clear and restart
     C                   eval      AttrDefd= x'BA'
     C                   exsr      setComputerShp
     C                   eval      GridD=GridC
 3B  C                   for       x=1 to 100
 4B  C                   if        GridD(x)=' '
     C                   eval      GridD(x)='.'
     C                   eval      AttrDefd(x)= x'BA'                           blue
 4X  C                   else
     C                   eval      AttrDefd(x)= x'A1'                           green reverse
 4E  C                   endif
 3E  C                   endfor
      *
      *         ------------------------------------------------------------------------------------
      *         reload the start row/col and direction for user.
      *         ------------------------------------------------------------------------------------
     C                   eval      OverlayHHH = GridD
 3B  C                   for       ss = 2 to 5
     C                   eval      x=%scan(%char(ss):HHH)
     C                   eval      Srow(ss) = getrow(x)
     C                   eval      Scol(ss) = getcol(x)
     C                   eval      Sdir(ss)='H'
     C                   eval      y = RIGHTone(x:HHH:'SGL')                      see if left  OK
 4B  C                   if        y>100
     C                   eval      Sdir(ss)='V'
 4X  C                   else
 5B  C                   if        Gridd(y)<>Gridd(X)
     C                   eval      Sdir(ss)='V'
 5E  C                   endif
 4E  C                   endif
 3E  C                   endfor
      *
 1I  C                   iter
 2E  C                   endif
      *
      *     ----------------------------------------------------------------------------------------
      *     Let the battle begin..
      *     First make sure user has deployed ships.
      *     ----------------------------------------------------------------------------------------
 2B  C                   if        fkey=f10
     C                   eval      DeployedFlg = *off
 3B  C                   for       x=1 to 100
 4B  C                   if        GridD(x)<>'.'
     C                   eval      DeployedFlg = *on
 3L  C                   leave
 4E  C                   endif
 3E  C                   endfor
      *
 3B  C                   if        DeployedFlg=*on
 1L  C                   leave
 3X  C                   else
     C                   eval      *in10=*on
 1I  C                   iter
 3E  C                   endif
 2E  C                   endif
     C                   clear                   Gridw
      *
      *     ----------------------------------------------------------------------------------------
      *     Do a little editing to make sure users selects with the grid.
      *     ----------------------------------------------------------------------------------------
 2B  C                   for       ShipSize=2 to 5
 3B  C                   if        scol(ShipSize)<1
     C                   eval      scol(shipsize)= 1
 3E  C                   endif
 3B  C                   if        scol(ShipSize)>10
     C                   eval      scol(shipsize)= 10
 3E  C                   endif
 3B  C                   if        srow(ShipSize)<1
     C                   eval      srow(shipsize)= 1
 3E  C                   endif
 3B  C                   if        srow(ShipSize)>10
     C                   eval      srow(shipsize)= 10
 3E  C                   endif
 3B  C                   if        sdir(ShipSize) = 'V' or
     C                             sdir(ShipSize) = 'H'
 3X  C                   else
     C                   eval      sdir(ShipSize)= 'H'
 3E  C                   endif
      *
     C                   eval      Row = Srow(ShipSize)
     C                   eval      Col = Scol(ShipSize)
 3B  C                   select
 3X  C                   when      Sdir(shipsize)='V'
     C                   eval      randVector = 3
 3X  C                   when      Sdir(shipsize)='H'
     C                   eval      randVector = 2
 3E  C                   endsl
     C                   exsr      LoadShip
      *
      *   ------------------------------------------------------------------------------------------
      *   If user placement causes a collision,  reset the current boat to a random position.
      *   Get random number between 1 and 100.
      *   ------------------------------------------------------------------------------------------
 3B  C                   if        CollisionFlag=*on
 4B  C                   dou       CollisionFlag=*off
     C                   eval      randIndex  = GetRandom(100)                  get random number
     C                   eval      sizecount = 0
     C                   eval      row   = getrow(randIndex)
     C                   eval      col   = getcol(randIndex)
     C                   Exsr      LoadShip
     C                   eval      srow(ShipSize) = getrow(randIndex)
     C                   eval      scol(ShipSize) = getcol(randIndex)
 4E  C                   enddo
 3E  C                   endif
 2E  C                   endfor
      *     ----------------------------------------------------------------------------------------
     C                   eval      gridD=gridw                                  load work grid
      *
 2B  C                   for       x=1 to 100
 3B  C                   if        GridD(x)=' '
     C                   eval      GridD(x)='.'
     C                   eval      AttrDefd(x)= x'BA'                           blue
 3X  C                   else
     C                   eval      AttrDefd(x)= x'A1'                           green reverse
 3E  C                   endif
 2E  C                   endfor
      * --------------------------------------------------------------------------------------------
 1E  C                   enddo
     C                   eval      GridDsave=GridD                              save for sunk placem
     C                   endsr
      *
      *   ------------------------------------------------------------------------------------------
      *   Load grid.
      *   We gots to be concerned about ships trying to run off the grid
      *                                 ships trying to overlay each other
      *   We know the length of the ship,  the direction the ship is going, and the size
      *   of the grid.  If a ship is going to run off the grid,  back up the starting point
      *   until the ship will fit.
      *   ------------------------------------------------------------------------------------------
     C     LoadShip      begsr
     C                   eval      CollisionFlag = *off
 1B  C                   select
 1X  C                   when      randVector=1                                  go up from start
 2B  C                   dow       ShipSize>Row
     C                   eval      Row = Row +1
 2E  C                   enddo
      *
 1X  C                   when      randVector=3                                  go down from start
 2B  C                   dow       (11-ShipSize)<Row
     C                   eval      Row = Row -1
 2E  C                   enddo
      *
 1X  C                   when      randVector=2                                  go right from start
 2B  C                   dow       (11-ShipSize)<col
     C                   eval      Col = Col - 1
 2E  C                   enddo
      *
 1X  C                   when      randVector=4                                  go left from start
 2B  C                   dow       ShipSize>Col
     C                   eval      Col = Col + 1
 2E  C                   enddo
 1E  C                   endsl
     C                   eval      randIndex  = getx(row:col)                   get new start
      *
      *   ------------------------------------------------------------------------------------------
      *   Before any values are loaded,  we have to make sure that all this ships coordinates aren't
      *   occupied by another ship.  If so,  get new random numbers for a starting point and
      *   start over with the ship placement process.
      *   ------------------------------------------------------------------------------------------
 1B  C                   do        ShipSize
 2B  C                   select
 2X  C                   when      randVector=1                                  go up from start
 3B  C                   if        GridW(getx(row:col)) <> *blanks
     C                   eval      CollisionFlag = *on
 lsr C                   leavesr
 3E  C                   endif
     C                   eval      Row = Row -1
      *
 2X  C                   when      randVector=3                                  go down from start
 3B  C                   if        GridW(getx(row:col)) <> *blanks
     C                   eval      CollisionFlag = *on
 lsr C                   leavesr
 3E  C                   endif
     C                   eval      Row = Row + 1
      *
 2X  C                   when      randVector=2                                  go right from start
 3B  C                   if        GridW(getx(row:col)) <> *blanks
     C                   eval      CollisionFlag = *on
 lsr C                   leavesr
 3E  C                   endif
     C                   eval      Col = Col + 1
      *
 2X  C                   when      randVector=4                                  go left from start
 3B  C                   if        GridW(getx(row:col)) <> *blanks
     C                   eval      CollisionFlag = *on
 lsr C                   leavesr
 3E  C                   endif
     C                   eval      Col = Col - 1
 2E  C                   endsl
 1E  C                   enddo
      *
      *   ------------------------------------------------------------------------------------------
      *   Load values for the ships.
      *   ------------------------------------------------------------------------------------------
     C                   eval      row   = getrow(randIndex)
     C                   eval      col   = getcol(randIndex)
      *
 1B  C                   do        ShipSize
 2B  C                   select
 2X  C                   when      randVector=1                                  go up from start
     C                   eval      GridW(getx(row:col)) = %char(ShipSize)
     C                   eval      Row = Row - 1
      *
 2X  C                   when      randVector=3                                  go down from start
     C                   eval      GridW(getx(row:col)) = %char(ShipSize)
     C                   eval      Row = Row + 1
      *
 2X  C                   when      randVector=2                                  go right from start
     C                   eval      GridW(getx(row:col)) = %char(ShipSize)
     C                   eval      Col = Col + 1
      *
 2X  C                   when      randVector=4                                  go left from start
     C                   eval      GridW(getx(row:col)) = %char(ShipSize)
     C                   eval      Col = Col - 1
 2E  C                   endsl
 1E  C                   enddo
     C                   endsr
      *
      * --------------------------------------------------------------------------------------------
      * randVector    = 1,2,3 or 4.  Arbitrarily 1=up, 2=right, 3=down, 4=left
      * randIndex = random starting point for ships.
      * ShipSize   = number of indexes occupied by each ship.  2, 3,  4,  5 respectively.
      * --------------------------------------------------------------------------------------------
     C     setComputerShpbegsr
     C                   clear                   GridC
 1B  C                   for       ShipSize=2 to 5
     C                   eval      randVector    = GetRandom(4)                 get random number
      *
 2B  C                   dou       CollisionFlag=*off
     C                   eval      randIndex  = GetRandom(100)                  Random starting
     C                   eval      sizecount = 0
     C                   eval      row   = getrow(randIndex)
     C                   eval      col   = getcol(randIndex)
     C                   eval      gridw=gridc                                  load work grid
     C                   Exsr      LoadShip
     C                   eval      gridc=gridw                                  unload work grid
 2E  C                   enddo
 1E  C                   endfor
     C                   endsr
      *
      *---------------------------------------------------------------------------------------------
      *  convert row,column indexing to single level indexing
      *  The formula is (Row-1) * (# elements in a column) + column number
      *---------------------------------------------------------------------------------------------
     Pgetx             B                                                        Begin Procedure
     D getx            pi             3u 0                                      Procedure Interface
     D   row                          3u 0 const                                 incoming arguement
     D   col                          3u 0 const                                 incoming arguement
     D   ax            s              3u 0
     C                   eval      ax=((row-1)*10)+col
     C                   return    ax                                           return value
     Pgetx             E                                                        End Procedure
      *
      *---------------------------------------------------------------------------------------------
      *  Return the virtual row number for a real array index value
      *  Row / (# cols in a row) + 1 (if col# > 0)
      *---------------------------------------------------------------------------------------------
     Pgetrow           B                                                        Begin Procedure
     D getrow          pi             3u 0                                      Procedure Interface
     D   arrayindex                   3u 0 const                                 incoming arguement
     D   row           s              3u 0
     D   col           s              3u 0
     C                   eval      row=%div(arrayindex:10)
     C                   eval      col=%rem(arrayindex:10)
 1B  C                   if        col>0
     C                   eval      row=row+1
 1E  C                   endif
     C                   return    row
     Pgetrow           E                                                        End Procedure
      *
      *---------------------------------------------------------------------------------------------
      *  Return the virtual col number for a real array index value
      *  Row / (# cols in a row) + 1 (if col# > 0)
      *---------------------------------------------------------------------------------------------
     Pgetcol           B                                                        Begin Procedure
     D getcol          pi             3u 0                                      Procedure Interface
     D   arrayindex                   3u 0 const                                 incoming arguement
     D   col           s              3u 0
     D   row           s              3u 0
     C                   eval      row=%div(arrayindex:10)
     C                   eval      col=%rem(arrayindex:10)
 1B  C                   if        col=0
     C                   eval      col=10
 1E  C                   endif
     C                   return    col                                          return value
     Pgetcol           E                                                        End Procedure
      *
      *
      *---------------------------------------------------------------------------------------------
      *  Return the true array index of the coordinate in-line one row above the passed in index.
      *  If location not available to bomb,  return 125
      *---------------------------------------------------------------------------------------------
     PUPone            B                                                        Begin Procedure
     D UPone           pi             3u 0                                      Procedure Interface
     D   currentindex                 3u 0                                       incoming arguement
     D   HHH                        100
     D   TypeScan                     3    const
      *
     D   newindex      s              3u 0
     D   row           s              3u 0
     D   col           s              3u 0
     C                   eval      row   = getrow(currentindex)                 go to row notation
     C                   eval      col   = getcol(currentindex)
 1B  C                   if        row=1
     C                   eval      newindex=125
 1X  C                   else
     C                   eval      row = row - 1
     C                   eval      newindex = getx(row:col)
      *
 2B  C                   select
 2X  C                   when      %subst(HHH:newindex:1) = 'S' or
     C                             %subst(HHH:newindex:1) = 'm'
     C                   eval      newindex=125
 2X  C                   when      %subst(HHH:newindex:1) = 'H'
     C                             and TypeScan = 'SGL'
     C                   eval      newindex=110
 2E  C                   endsl
 1E  C                   endif
      *
     C                   return    newindex
     PUPone            E                                                        End Procedure
      *
      *
      *---------------------------------------------------------------------------------------------
      *  Return the true array index of the coordinate in-line one row below the passed in index.
      *  If location not available to bomb,  return 125
      *---------------------------------------------------------------------------------------------
     PDOWNone          B                                                        Begin Procedure
     D DOWNone         pi             3u 0                                      Procedure Interface
     D   currentindex                 3u 0                                       incoming arguement
     D   HHH                        100
     D   TypeScan                     3    const
      *
     D   newindex      s              3u 0
     D   row           s              3u 0
     D   col           s              3u 0
     C                   eval      row   = getrow(currentindex)                 go to row notation
     C                   eval      col   = getcol(currentindex)
 1B  C                   if        row=10
     C                   eval      newindex=125
 1X  C                   else
     C                   eval      Row = Row + 1
     C                   eval      newindex = getx(row:col)
      *
 2B  C                   select
 2X  C                   when      %subst(HHH:newindex:1) = 'S' or
     C                             %subst(HHH:newindex:1) = 'm'
     C                   eval      newindex=125
 2X  C                   when      %subst(HHH:newindex:1) = 'H'
     C                             and TypeScan = 'SGL'
     C                   eval      newindex=110
 2E  C                   endsl
 1E  C                   endif
      *
     C                   return    newindex
     PDOWNone          E                                                        End Procedure
      *
      *
      *---------------------------------------------------------------------------------------------
      *  Return the true array index of the coordinate in-line one col to left  of passed index.
      *  If location not available to bomb,  return 125
      *---------------------------------------------------------------------------------------------
     PLEFTone          B                                                        Begin Procedure
     D LEFTone         pi             3u 0                                      Procedure Interface
     D   currentindex                 3u 0                                       incoming arguement
     D   HHH                        100
     D   TypeScan                     3    const
      *
     D   newindex      s              3u 0
     D   row           s              3u 0
     D   col           s              3u 0
     C                   eval      row   = getrow(currentindex)                 go to row notation
     C                   eval      col   = getcol(currentindex)
 1B  C                   if        col=1
     C                   eval      newindex=125
 1X  C                   else
     C                   eval      col = col - 1
     C                   eval      newindex = getx(row:col)
      *
 2B  C                   select
 2X  C                   when      %subst(HHH:newindex:1) = 'S' or
     C                             %subst(HHH:newindex:1) = 'm'
     C                   eval      newindex=125
 2X  C                   when      %subst(HHH:newindex:1) = 'H'
     C                             and TypeScan = 'SGL'
     C                   eval      newindex=110
 2E  C                   endsl
 1E  C                   endif
      *
     C                   return    newindex
     PLEFTone          E                                                        End Procedure
      *
      *---------------------------------------------------------------------------------------------
      *  Return the true array index of the coordinate in-line one col to right of passed index.
      *  If location not available to bomb,  return 125
      *---------------------------------------------------------------------------------------------
     PRIGHTone         B                                                        Begin Procedure
     D RIGHTone        pi             3u 0                                      Procedure Interface
     D   currentindex                 3u 0                                       incoming arguement
     D   HHH                        100
     D   TypeScan                     3    const
      *
     D   newindex      s              3u 0
     D   row           s              3u 0
     D   col           s              3u 0
     C                   eval      row   = getrow(currentindex)                 go to row notation
     C                   eval      col   = getcol(currentindex)
 1B  C                   if        col=10
     C                   eval      newindex=125
 1X  C                   else
     C                   eval      col = col + 1
     C                   eval      newindex = getx(row:col)
      *
 2B  C                   select
 2X  C                   when      %subst(HHH:newindex:1) = 'S' or
     C                             %subst(HHH:newindex:1) = 'm'
     C                   eval      newindex=125
 2X  C                   when      %subst(HHH:newindex:1) = 'H'
     C                             and TypeScan = 'SGL'
     C                   eval      newindex=110
 2E  C                   endsl
 1E  C                   endif
      *
     C                   return    newindex
     PRIGHTone         E                                                        End Procedure
      *
      *---------------------------------------------------------------------------------------------
      *  Get random number.
      *---------------------------------------------------------------------------------------------
     PGetRandom        B                                                        Begin Procedure
     D GetRandom       pi             3u 0                                      Procedure Interface
     D RandUpperLim                   3u 0 const                                Upper Limiting Val
      *
     D RandNum         s              3u 0                                      random number
     D RandFloat8      s              8f   inz                                  double precision
     D RandInt4        s             10i 0 inz STATIC                           unsigned integer
     D RandAlpha8      s              8a   inz                                  feed back
      *
     C                   CALLB(d)  'CEERAN0'
     C                   parm                    RandInt4
     C                   parm                    RandFloat8
     C                   parm                    RandAlpha8
     C                   eval      RandNum=(RandUpperLim * RandFloat8) + 1      apply upper limit
      *
     C                   return    RandNum                                      return value
     PGetRandom        E                                                        End Procedure
