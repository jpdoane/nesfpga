#include<math.h>

class VerClock
{
    private:
    double m_period;
    double m_last_re;
    double m_last_fe;

    public:

    VerClock(double period, double phase=0.0):
        m_period(period), m_last_re(-phase), m_last_fe(m_last_re-period/2) {}

    int level() { return m_last_re > m_last_fe; };

    double next_edge() {return level() ? m_last_re + m_period/2 : m_last_fe + m_period/2; };
    double tick(){
        double tnow = next_edge();
        if(level()) return m_last_fe = tnow;
        return  m_last_re = tnow;
    }

    int maybe_tick(double tnew)
    {
        if (tnew != next_edge()) return 0;
        tick();
        return 1;
    }

    bool rising_edge(double t) {return t == m_last_re;};
    bool falling_edge(double t) {return t == m_last_fe;};
};

class VerMultiClock
{
    private:
    double m_now;
    VerClock** m_clocks;
    int m_Nclocks;

    public:
    VerMultiClock(VerClock** clocks, int Nclocks):
        m_now(0.0), m_clocks(clocks), m_Nclocks(Nclocks) {}

    double now() {return m_now;};

    double tick()
    {
        // find next edge
        double nextedge = 0;
        double edge;
        for(int nn=0; nn<m_Nclocks; nn++)
        {
            edge = m_clocks[nn]->next_edge();
            if (nn == 0 || edge < nextedge) nextedge=edge;
        }
        // if (m_now == nextedge) 
        // {
            // std::cout << "tick() " << m_now << " -> "
            //                                 << m_clocks[0]->next_edge()   << ", "
            //                                 << m_clocks[1]->next_edge()  <<std::endl;

        // }
        m_now = nextedge;
        // tick clocks that match that edge
        for (int nn=0;nn<m_Nclocks;nn++)
            m_clocks[nn]->maybe_tick(m_now);
        
        return m_now;
    }
};
