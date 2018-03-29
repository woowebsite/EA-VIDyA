//+------------------------------------------------------------------+
//|                                               SignalCrossEMA.mqh |
//|                      Copyright � 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//|                                              Revision 2010.10.12 |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals based on crossup of two EMA                      |
//| Type=Signal                                                      |
//| Name=CrossEMA                                                    |
//| Class=CSignalCrossEMA                                            |
//| Page=                                                            |
//| Parameter=FastPeriod,int,12                                      |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalCrossEMA.                                           |
//| Appointment: Class trading signals cross two EMA.                |
//|              Derives from class CExpertSignal.                   |
//+------------------------------------------------------------------+
class CSignalCrossEMA : public CExpertSignal
  {
protected:
   CiMA             *m_Trend;
   CiMA             *m_BasisMA;
   CiMA             *m_Fast;
   CiMA             *m_Slow;
   CiVIDyA          *m_VIDyA;
   CiVIDyA          *m_VIDyA_Slow;
   CiADXWilder      *adx;
   CiWPR            *m_WPR;
   //--- input parameters
   int               m_basis_period;
   int               m_fast_period;
   int               m_slow_period;
   int               m_trend_period;
   int               adx_period;
   double            m_limit;            // level to place a pending order relative to the MA
   double            m_stop_loss;       // level to place a stop loss order relative to the open price
   double            m_take_profit;     // level to place a take profit order relative to the open price
   bool              is_buy_take_profit;
   bool              is_sell_take_profit;
   


public:
                     CSignalCrossEMA();
                    ~CSignalCrossEMA();
   //--- methods initialize protected data
   void              FastPeriod(int period) { m_fast_period=period;                }
   void              BasisPeriod(int period) { m_basis_period=period;                }
   void              SlowPeriod(int period) { m_slow_period=period;                }
   void              TrendPeriod(int period) { m_trend_period=period;                }
   void              ADXPeriod(int period) { adx_period=period;                }

   virtual bool      InitIndicators(CIndicators* indicators);
   virtual bool      ValidationSettings();
   //---
   virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseLong(double& price);
   virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
   virtual bool      CheckCloseShort(double& price);

protected:
   bool              InitFastEMA(CIndicators* indicators);
   bool              InitBasisMA(CIndicators* indicators);
   bool              InitSlowEMA(CIndicators* indicators);
   bool              InitTrendMA(CIndicators* indicators);
   bool              InitVIDyA(CIndicators* indicators);
   bool              InitVIDyASlow(CIndicators* indicators);
   bool              InitADX(CIndicators* indicators);
   bool              InitWPR(CIndicators* indicators);

   //---
   double            FastEMA(int ind)       { return(m_Fast.Main(ind));         }
   double            BasisMA(int ind)       { return(m_BasisMA.Main(ind));      }
   double            SlowEMA(int ind)       { return(m_Slow.Main(ind));         }
   double            TrendMA(int ind)       { return(m_Trend.Main(ind));        }
   double            VIDyA(int ind)         { return(m_VIDyA.Main(ind));        }
   double            VIDyA_Slow(int ind)    { return(m_VIDyA_Slow.Main(ind));        }

public:
   void               StopLoss(double value)              { m_stop_loss=value;   }
   void               TakeProfit(double value)            { m_take_profit=value; }
   void               Expiration(int value)               { m_expiration=value;  }
  };
//+------------------------------------------------------------------+
//| Constructor CSignalCrossEMA.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSignalCrossEMA::CSignalCrossEMA()
  {
//--- initialize protected data
   m_Trend     =NULL;
   m_BasisMA     =NULL;
   m_Fast     =NULL;
   m_Slow     =NULL;
   adx           =NULL;
   m_WPR           =NULL;
//--- set default inputs
   m_basis_period =20;
   m_fast_period =76;
   m_slow_period =292;
   m_trend_period =469;
   m_limit      =0.0;
   m_stop_loss  =50.0;
   m_take_profit=100.0;
   m_expiration =0;
  }
//+------------------------------------------------------------------+
//| Destructor CSignalCrossEMA.                                      |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSignalCrossEMA::~CSignalCrossEMA()
  {
//---
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//| INPUT:  no.                                                      |
//| OUTPUT: true-if settings are correct, false otherwise.           |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::ValidationSettings()
  {
  //  if(m_fast_period>=m_slow_period || m_slow_period >= m_trend_period)
  //    {
  //     printf(__FUNCTION__+": period of slow EMA must be greater than period of fast EMA");
  //     return(false);
  //   }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitIndicators(CIndicators* indicators)
  {
//--- check
   if(indicators==NULL)         return(false);
   if(!InitFastEMA(indicators)) return(false);
  //  if(!InitBasisMA(indicators)) return(false);
  //  if(!InitSlowEMA(indicators)) return(false);
   if(!InitTrendMA(indicators)) return(false);
   if(!InitVIDyA(indicators)) return(false);
   if(!InitVIDyASlow(indicators)) return(false);
   if(!InitADX(indicators)) return(false);
   if(!InitWPR(indicators)) return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create fast EMA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitFastEMA(CIndicators* indicators)
  {
//--- create fast EMA indicator
   if(m_Fast==NULL)
      if((m_Fast=new CiMA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add fast EMA indicator to collection
    if(!indicators.Add(m_Fast))
    {
      printf(__FUNCTION__+": error adding object");
      delete m_Fast;
      return(false);
    }
//--- initialize fast EMA indicator
    if(!m_Fast.Create(m_symbol.Name(),m_period,m_fast_period,0,MODE_EMA,PRICE_CLOSE))
    {
      printf(__FUNCTION__+": error initializing object");
      return(false);
      return(false);
    }
    m_Fast.BufferResize(1000);
//--- ok
    return(true);
  }

//+------------------------------------------------------------------+
//| Create basis MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitBasisMA(CIndicators* indicators)
  {
    // return false;   //Disable MA20
//--- create basis EMA indicator
   if(m_BasisMA==NULL)
      if((m_BasisMA=new CiMA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add fast EMA indicator to collection
   if(!indicators.Add(m_BasisMA))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_BasisMA;
      return(false);
     }
//--- initialize fast EMA indicator
   if(!m_BasisMA.Create(m_symbol.Name(),m_period,m_basis_period,0,MODE_SMA,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_BasisMA.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create slow EMA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitSlowEMA(CIndicators* indicators)
  {
//--- create slow EMA indicator
   if(m_Slow==NULL)
      if((m_Slow=new CiMA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
   if(!indicators.Add(m_Slow))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_Slow;
      return(false);
     }
//--- initialize slow EMA indicator
   if(!m_Slow.Create(m_symbol.Name(),m_period,m_slow_period,0,MODE_SMA,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_Slow.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create trend MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitTrendMA(CIndicators* indicators)
  {
//--- create slow EMA indicator
   if(m_Trend==NULL)
      if((m_Trend=new CiMA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
   if(!indicators.Add(m_Trend))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_Trend;
      return(false);
     }
//--- initialize slow EMA indicator
   if(!m_Trend.Create(m_symbol.Name(),m_period,m_trend_period,0,MODE_SMA,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_Trend.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create trend MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitVIDyA(CIndicators* indicators)
  {
//--- create slow EMA indicator
   if(m_VIDyA==NULL)
      if((m_VIDyA=new CiVIDyA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
   if(!indicators.Add(m_VIDyA))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_VIDyA;
      return(false);
     }
//--- initialize slow EMA indicator
   if(!m_VIDyA.Create(m_symbol.Name(),m_period,9,12,0,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_VIDyA.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create trend MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitVIDyASlow(CIndicators* indicators)
  {
//--- create slow EMA indicator
   if(m_VIDyA_Slow==NULL)
      if((m_VIDyA_Slow=new CiVIDyA)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
   if(!indicators.Add(m_VIDyA_Slow))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_VIDyA_Slow;
      return(false);
     }
//--- initialize slow EMA indicator
   if(!m_VIDyA_Slow.Create(m_symbol.Name(),m_period,30,40,0,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   m_VIDyA_Slow.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create trend MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitADX(CIndicators* indicators)
  {
//--- create slow EMA indicator
   if(adx==NULL)
      if((adx=new CiADXWilder)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
   if(!indicators.Add(adx))
     {
      printf(__FUNCTION__+": error adding object");
      delete adx;
      return(false);
     }
//--- initialize slow EMA indicator
   if(!adx.Create(m_symbol.Name(),m_period,adx_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   adx.BufferResize(1000);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| Create trend MA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitWPR(CIndicators* indicators)
  {
//--- create slow EMA indicator
    if(m_WPR==NULL)
      if((m_WPR=new CiWPR)==NULL)
        {
         printf(__FUNCTION__+": error creating object");
         return(false);
        }
//--- add slow EMA indicator to collection
    if(!indicators.Add(m_WPR))
     {
      printf(__FUNCTION__+": error adding object");
      delete m_WPR;
      return(false);
     }
//--- initialize slow EMA indicator
    if(!m_WPR.Create(m_symbol.Name(),m_period,14))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
    m_WPR.BufferResize(1000);
//--- ok
    return(true);
  }

//+------------------------------------------------------------------+
//| Cross Moving Average singal                                      |
//| INPUT:  fastMA     - refernce for fast MA,                       |
//|         slowMA     - refernce for slow MA,                       |
//| OUTPUT: true-if fast MA cross slow MA                            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+

  //CROSS DOWN
  bool crossdown(CiMA* fastMA, CiMA* slowMA){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double slowMA1 = slowMA.Main(1);
    double slowMA2 = slowMA.Main(2);
    
    if( (fastMA2-slowMA2 > 0)  &&  (fastMA1-slowMA1 < 0) ) 
      return (true);
     
    return (false);
  }

  bool crossdown(CiMA* fastMA, CiVIDyA* vidya){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double vidya1 = vidya.Main(1);
    double vidya2 = vidya.Main(2);

    
    if( (fastMA2 > vidya2)  &&  (fastMA1 < vidya1) ) 
      return (true);
    return (false);
  }

  bool crossdown(CiVIDyA* vidya, CiMA* fastMA){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double vidya1 = vidya.Main(1);
    double vidya2 = vidya.Main(2);

    
    if( (vidya2  > fastMA2)  &&  (vidya1 < fastMA1) ) 
      return (true);
    return (false);
  }

  //CROSS UP
  bool crossup(CiMA* fastMA, CiMA* slowMA){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double slowMA1 = slowMA.Main(1);
    double slowMA2 = slowMA.Main(2);

    
    if( (fastMA2-slowMA2 < 0)  &&  (fastMA1-slowMA1 > 0) ) 
      return (true);
    return (false);
  }

  bool crossup(CiVIDyA* vidya, CiMA* fastMA){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double vidya1 = vidya.Main(1);
    double vidya2 = vidya.Main(2);

    
    if( (vidya2 - fastMA2 < 0)  &&  (vidya1 - fastMA1 > 0) ) 
      return (true);
    return (false);
  }

  bool crossup(CiMA* fastMA, CiVIDyA* vidya){
    double fastMA1 = fastMA.Main(1);
    double fastMA2 = fastMA.Main(2);
    double vidya1 = vidya.Main(1);
    double vidya2 = vidya.Main(2);

    
    if( (fastMA2-vidya2 < 0)  &&  (fastMA1-vidya1 > 0) ) 
      return (true);
    return (false);
  }

  bool above(CiMA* fastMA, CiMA* slowMA){
    double fastMA1 = fastMA.Main(1);
    double slowMA1 = slowMA.Main(1);

    if(  fastMA1-slowMA1 > 0 ) 
      return (true);
    return (false);
  }

  bool above(CiMA* fastMA, CiVIDyA* vidya){
    double fastMA1 = fastMA.Main(1);
    double vidya1 = vidya.Main(1);

    if(  fastMA1 > vidya1 ) 
      return (true);
    return (false);
  }

  bool above(CiVIDyA* vidya, CiMA* fastMA ){
    double fastMA1 = fastMA.Main(1);
    double vidya1 = vidya.Main(1);

    if(  vidya1 - fastMA1 > 0 ) 
      return (true);
    return (false);
  }

  bool above(CiVIDyA* via_fast, CiVIDyA* via_slow){
    double f = via_fast.Main(1);
    double s = via_slow.Main(1);

    if(f-s > 0) 
      return (true);
    return (false);
  }

  bool moveup(CiMA* ma){
    return  ma.Main(9) < ma.Main(1);
  }

  bool moveup(CiVIDyA* ma){
    return  ma.Main(2) < ma.Main(1);
  }

  bool movedown(CiMA* ma){
    return  ma.Main(9) > ma.Main(1);
  }

  bool movedown(CiVIDyA* ma){
    return  ma.Main(2) > ma.Main(1);
  }

  //ADX
  bool adxStrong(CiADXWilder* adx){
    double ADX1=adx.Main(1);
    double ADX2=adx.Main(2);
    return ADX1 >= 20 && ADX1 > ADX2 ;
  }
  bool adxGrowingUp(CiADXWilder* adx){
    double DIPlus=adx.Plus(1);
    double DIMinus=adx.Minus(1);
    double ADX1=adx.Main(1);

    return DIMinus < DIPlus && DIMinus < ADX1;
  }
 
  bool adxGrowingDown(CiADXWilder* adx){
    double DIPlus=adx.Plus(1);
    double DIMinus=adx.Minus(1);
    double ADX1=adx.Main(1);

    return DIMinus > DIPlus && DIPlus < ADX1;
  }


  //William R
  bool WPRCrossUp(CiWPR *wpr){
    double w1 = wpr.Main(1);
    double w2 = wpr.Main(2);
    return w2 < -50 && w1 >= -50;
  }
  bool WPRCrossUpStrong(CiWPR *wpr){
    double w1 = wpr.Main(1);
    double w2 = wpr.Main(2);
    return w2 < -20 && w1 >= -20;
  }
  bool WPRCrossDown(CiWPR *wpr){
    double w1 = wpr.Main(1);
    double w2 = wpr.Main(2);
    return w2 > -50 && w1 <= -50;
  }
  bool WPRCrossDown2(CiWPR *wpr){
    double w1 = wpr.Main(1);
    double w2 = wpr.Main(2);
    return w1 < -20 && w2 >= -20;
  }
  bool WPRCrossDownStrong(CiWPR *wpr){
    double w1 = wpr.Main(1);
    double w2 = wpr.Main(2);
    return w2 > -80 && w1 <= -80;
  }
  
 

//+------------------------------------------------------------------+
//| Check conditions for long position open.                         |
//| INPUT:  price      - refernce for price,                         |
//|         sl         - refernce for stop loss,                     |
//|         tp         - refernce for take profit,                   |
//|         expiration - refernce for expiration.                    |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
  {
    //BUY CONTINUE 1
    //PRICE: VIDyA Fast
    if(
      above(m_VIDyA, m_VIDyA_Slow)
      && moveup(m_VIDyA)
      && moveup(m_Fast)
      && WPRCrossDown(m_WPR)
    ) 
    {
      is_buy_take_profit    = false;
      double mFast          = FastEMA(1);
      double vidya          = VIDyA(1);
      double vidya_slow     = VIDyA_Slow(1);
      double mTrend         = TrendMA(1);
      double spread         = m_symbol.Ask()-m_symbol.Bid();
      double unit           = PriceLevelUnit();

      double s1 = vidya - mFast;
      double s2 = mFast - vidya_slow;
      if(s1 < s2) return false;
      
      price = m_symbol.NormalizePrice(vidya - spread  * unit);
      sl    = m_symbol.NormalizePrice(mFast - m_stop_loss * unit);
      tp    = m_symbol.NormalizePrice(vidya + 1.618 * m_stop_loss * unit);

      //TP too large problem
      if(price - sl > 4 * m_stop_loss * unit) {
        sl = m_symbol.NormalizePrice(mFast);
      }


      expiration  +=  m_expiration * PeriodSeconds(m_period);
       
      return(true);
    }


    //BUY CONTINUE 2
    //PRICE: VIDyA Slow
    if(
      above(m_VIDyA_Slow, m_Trend)
      && above(m_VIDyA, m_VIDyA_Slow)
      && above(m_Fast, m_VIDyA)
      && WPRCrossUpStrong(m_WPR)
    ) 
    {
      is_buy_take_profit    = false;
      double mFast          = FastEMA(1);
      double vidya          = VIDyA(1);
      double vidya_slow     = VIDyA_Slow(1);
      double mTrend         = TrendMA(1);
      double spread         = m_symbol.Ask()-m_symbol.Bid();
      double unit           = PriceLevelUnit();

      double s1 = mFast - vidya;
      double s2 = vidya - mTrend;
      if(s1 < s2) return false;


      price = m_symbol.NormalizePrice(vidya - spread  * unit);
      sl    = m_symbol.NormalizePrice(vidya_slow - m_stop_loss * unit);
      tp    = m_symbol.NormalizePrice(vidya + 1.618 * m_stop_loss * unit);

      expiration  +=  m_expiration * PeriodSeconds(m_period);
       
      return(true);
    }

    //Canceled
    return(false);
  }

//+------------------------------------------------------------------+
//| Check conditions for long position close.                        |
//| INPUT:  price - refernce for price.                              |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckCloseLong(double& price)
  {
    if(crossdown(m_VIDyA, m_Fast )
    && above(m_Fast, m_VIDyA_Slow)
    && above(m_VIDyA, m_VIDyA_Slow)
    ) {
      double mFast          = FastEMA(1);
      price = m_symbol.NormalizePrice(mFast);
      return(true);
    }

    if(crossdown(m_VIDyA, m_Trend )
    && above(m_Fast, m_VIDyA_Slow)
    && above(m_VIDyA, m_VIDyA_Slow)
    ) {
      double mFast          = FastEMA(1);
      price = m_symbol.NormalizePrice(mFast);
      return(true);
    }
    
    if(WPRCrossDownStrong(m_WPR)
      && adxGrowingDown(adx) && adxStrong(adx)
    ) {
      price=m_symbol.NormalizePrice(m_symbol.Bid());
      return(true);
    }

    return(false);   
  }





//+------------------------------------------------------------------+
//| Check conditions for short position open.                        |
//| INPUT:  price      - refernce for price,                         |
//|         sl         - refernce for stop loss,                     |
//|         tp         - refernce for take profit,                   |
//|         expiration - refernce for expiration.                    |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
{

    //SELL CONTINUE 1
    //PRICE: VIDyA Fast
    if(
      above(m_VIDyA_Slow, m_VIDyA)
      && movedown(m_VIDyA)
      && movedown(m_Fast)
      && WPRCrossUp(m_WPR)
    ) 
    {
      is_buy_take_profit    = false;
      double mFast          = FastEMA(1);
      double vidya          = VIDyA(1);
      double vidya_slow     = VIDyA_Slow(1);
      double mTrend         = TrendMA(1);
      double spread         = m_symbol.Ask()-m_symbol.Bid();
      double unit           = PriceLevelUnit();

      double s1 = vidya - mFast;
      double s2 = mFast - vidya_slow;
      if(s1 < s2) return false;
      
      price = m_symbol.NormalizePrice(vidya + spread  * unit);
      sl    = m_symbol.NormalizePrice(mFast + m_stop_loss * unit);
      tp    = m_symbol.NormalizePrice(vidya - 1.618 * m_stop_loss * unit);

      //TP too large problem
      if(price - sl < 4 * m_stop_loss * unit) {
        sl = m_symbol.NormalizePrice(mFast);
      }


      expiration  +=  m_expiration * PeriodSeconds(m_period);
       
      return(true);
    }


    //SELL CONTINUE 2
    //PRICE: VIDyA Slow
    if(
      above(m_Trend, m_VIDyA_Slow)
      && above(m_VIDyA_Slow, m_VIDyA )
      && above(m_VIDyA, m_Fast )
      && WPRCrossDownStrong(m_WPR)
    ) 
    {
      is_buy_take_profit    = false;
      double mFast          = FastEMA(1);
      double vidya          = VIDyA(1);
      double vidya_slow     = VIDyA_Slow(1);
      double mTrend         = TrendMA(1);
      double spread         = m_symbol.Ask()-m_symbol.Bid();
      double unit           = PriceLevelUnit();

      double s1 = mFast - vidya;
      double s2 = vidya - mTrend;
      if(s1 < s2) return false;


      price = m_symbol.NormalizePrice(vidya + spread  * unit);
      sl    = m_symbol.NormalizePrice(vidya_slow + m_stop_loss * unit);
      tp    = m_symbol.NormalizePrice(vidya - 1.618 * m_stop_loss * unit);

      expiration  +=  m_expiration * PeriodSeconds(m_period);
       
      return(true);
    }

    return(false);
}



//+------------------------------------------------------------------+
//| Check conditions for short position close.                        |
//| INPUT:  price - refernce for price.                              |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckCloseShort(double& price)
  {
    if(crossup(m_VIDyA, m_Fast )
      && above(m_VIDyA_Slow, m_Fast)
      && above(m_VIDyA_Slow, m_VIDyA)
    ) {
      double mFast          = FastEMA(1);
      price = m_symbol.NormalizePrice(mFast);
      return(true);
    }

    if(crossup(m_VIDyA, m_Trend )
    && above(m_VIDyA_Slow, m_Fast)
    && above(m_VIDyA_Slow, m_VIDyA)
    ) {
      double mFast          = FastEMA(1);
      price = m_symbol.NormalizePrice(mFast);
      return(true);
    }
    
    if(WPRCrossUpStrong(m_WPR)
      && adxGrowingUp(adx) && adxStrong(adx)
    ) {
      price=m_symbol.NormalizePrice(m_symbol.Bid());
      return(true);
    }

    return(false);   
   
  }