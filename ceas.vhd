architecture Behavioral of ceas is
    
    component driver7seg is
    Port ( clk : in STD_LOGIC; --100MHz board clock input
           Din : in STD_LOGIC_VECTOR (15 downto 0); --16 bit binary data for 4 displays
           an : out STD_LOGIC_VECTOR (3 downto 0); --anode outputs selecting individual displays 3 to 0
           seg : out STD_LOGIC_VECTOR (0 to 6); -- cathode outputs for selecting LED-s in each display
           dp_in : in STD_LOGIC_VECTOR (3 downto 0); --decimal point input values
           dp_out : out STD_LOGIC; --selected decimal point sent to cathodes
           rst : in STD_LOGIC); --global reset
    end component driver7seg;
       
    component deBounce is
    port(   clk : in std_logic;
            rst : in std_logic;
            button_in : in std_logic;
            pulse_out : out std_logic
        );
    end component;
    
    type states is (afis_timp, set_ore, set_min, alarm, set_alarm_ore, set_alarm_min);
    signal current_state, next_state : states := afis_timp;
    
    signal btnLd, btnRd, btnDd : std_logic;
    
    constant n : integer := 10**8;
    signal inc_ore, inc_min, inc_sec, inc_alarm_ore, inc_alarm_min, inc_alarm_sec : std_logic;
    signal clk1hz : std_logic;
    signal blink_ora, blink_min : std_logic;
    signal an_int : std_logic_vector (3 downto 0);
    
    type sec is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 5;
    end record;
    type min is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 5;
    end record;
    type ore is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 2;
    end record;
    type timp is record
        min : min;
        sec : sec;
        ore : ore;
    end record;
    
    signal t : timp := ((0,0),(0,0),(0,0)) ;
    signal alarm_time : timp := ((0,0),(0,0),(0,0));
    
    signal ore_min : STD_LOGIC_VECTOR (15 downto 0);
    signal ore_min_alarm : STD_LOGIC_VECTOR (15 downto 0);
    
    signal d : STD_LOGIC_VECTOR (15 downto 0);
    
    
begin

deb1 : deBounce port map (clk => clk, rst => '0', button_in => btnL, pulse_out => btnLd);
deb3 : deBounce port map (clk => clk, rst => '0', button_in => btnR, pulse_out => btnRd);
deb4 : deBounce port map (clk => clk, rst => rst, button_in => btnD, pulse_out => btnDd);


process(rst, clk)
begin
  if rst = '1' then
    current_state <= afis_timp;
  elsif rising_edge(clk) then
    current_state <= next_state;  
  end if;
end process;

process (current_state, btnC, btnLd, btnRd, btnDd)
begin
    case (current_state) is
      when afis_timp =>
                   if btnLd = '1' then
                       next_state <= set_ore;
                   elsif btnDd = '1' then
                       next_state <= alarm;
                   else
                       next_state <= afis_timp;
                   end if;
                   led <= "00";
      when set_ore => if btnLd = '1' then
                        next_state <= set_min;
                      else
                        next_state<= set_ore;
                      end if;
                      led <= "00";
      when set_min => if btnLd = '1' then
                        next_state <= afis_timp;
                      else
                        next_state <= set_min;
                      end if;
                      led <= "00";
      when alarm => if btnLd = '1' then 
                      next_state <= set_alarm_ore;
                    elsif btnDd = '1' then
                       next_state <= afis_timp;
                    else
                      next_state <= alarm;
                    end if; 
                    led <= "11";
      when set_alarm_ore =>
                      if btnLd = '1' then
                        next_state <= set_alarm_min;
                      else 
                        next_state <= set_alarm_ore;
                      end if;
                      led <= "10";
      when set_alarm_min =>
                      if btnLd = '1' then
                        next_state <= alarm;
                       else
                        next_state <= set_alarm_min;
                       end if;
                       led <= "01";


      when others => next_state <= afis_timp;
    end case;
end process;
   
divider: process (rst, clk)
    variable counter : integer :=0;
begin
    if rst = '1' then
      counter := 0;
      inc_sec <= '1';
    elsif  rising_edge(clk) then
       if counter = n - 1 then
           counter := 0;
           inc_sec <= '1';
       else 
           counter := counter + 1;
           inc_sec <= '0';
       end if;
    end if;
end process;

inc_min <= '1' when current_state = set_min and btnRd = '1' else '0';
inc_ore <= '1' when current_state = set_ore and btnRd = '1' else '0';
inc_alarm_min <= '1' when current_state = set_alarm_min and btnRd = '1' else '0';
inc_alarm_ore <= '1' when current_state = set_alarm_ore and btnRd = '1' else '0';

process (rst, clk)
begin
    if rst = '1' then
      t.ore.dig2 <= 0;
      t.ore.dig1 <= 0;
      t.min.dig2 <= 0;
      t.min.dig1 <= 0;
      t.sec.dig2 <= 0;
      t.sec.dig1 <= 0;
      alarm_time.ore.dig2 <= 0;
      alarm_time.ore.dig1 <= 0;
      alarm_time.min.dig2 <= 0;
      alarm_time.min.dig1 <= 0;
      alarm_time.sec.dig2 <= 0;
      alarm_time.sec.dig1 <= 0;
    elsif rising_edge(clk) then
        if inc_sec = '1' then
            if t.sec.dig1 = 9 then
               t.sec.dig1 <= 0;
               if t.sec.dig2 = 5 then
                  t.sec.dig2 <= 0;
                  if t.min.dig1 = 9 then
                     t.min.dig1 <= 0;
                     if t.min.dig2 = 5 then
                        t.min.dig2 <= 0;
                        if t.ore.dig1 = 3 and t.ore.dig2 = 2 then
                            t.ore.dig1 <= 0;
                            t.ore.dig2 <= 0;
                        elsif t.ore.dig1 = 9 then
                            t.ore.dig1 <= 0;
                            t.ore.dig2 <= t.ore.dig2 + 1;
                        else 
                            t.ore.dig1 <= t.ore.dig1 + 1;
                        end if;
                     else
                        t.min.dig2 <= t.min.dig2 + 1;
                     end if;
                  else
                     t.min.dig1 <= t.min.dig1 + 1;   
                  end if;
              else
                  t.sec.dig2 <= t.sec.dig2 + 1; 
              end if;
            else 
                t.sec.dig1 <= t.sec.dig1 + 1;
            end if;
        
        elsif inc_min = '1' then
            if t.min.dig1 = 9 then
               t.min.dig1 <= 0;
               if t.min.dig2 = 5 then
                  t.min.dig2 <= 0;
               else
                  t.min.dig2 <= t.min.dig2 + 1;
               end if;
            else
               t.min.dig1 <= t.min.dig1 + 1;   
            end if; 
        
        elsif inc_ore = '1' then
            if t.ore.dig1 = 3 and t.ore.dig2 = 2 then
                t.ore.dig1 <= 0;
                t.ore.dig2 <= 0;
            elsif t.ore.dig1 = 9 then
                t.ore.dig1 <= 0;
                t.ore.dig2 <= t.ore.dig2 + 1;
            else 
                 t.ore.dig1 <= t.ore.dig1 + 1;
            end if;
        elsif inc_alarm_min = '1' then
                           if alarm_time.min.dig1 = 9 then
                               alarm_time.min.dig1 <= 0;
                               if alarm_time.min.dig2 = 5 then
                                   alarm_time.min.dig2 <= 0;
                               else
                                   alarm_time.min.dig2 <= alarm_time.min.dig2 + 1;
                               end if;
                           else
                               alarm_time.min.dig1 <= alarm_time.min.dig1 + 1;   
                           end if; 
           
                       elsif inc_alarm_ore = '1' then
                           if alarm_time.ore.dig1 = 3 and alarm_time.ore.dig2 = 2 then
                               alarm_time.ore.dig1 <= 0;
                               alarm_time.ore.dig2 <= 0;
                           elsif alarm_time.ore.dig1 = 9 then
                               alarm_time.ore.dig1 <= 0;
                               alarm_time.ore.dig2 <= alarm_time.ore.dig2 + 1;
                           else 
                               alarm_time.ore.dig1 <= alarm_time.ore.dig1 + 1;
                           end if;
                       end if;
                   end if;
               end process;


ore_min <= std_logic_vector(to_unsigned(t.ore.dig2,4)) &
                                 std_logic_vector(to_unsigned(t.ore.dig1,4)) &
                                 std_logic_vector(to_unsigned(t.min.dig2,4)) &
                                 std_logic_vector(to_unsigned(t.min.dig1,4));
ore_min_alarm <= std_logic_vector(to_unsigned(alarm_time.ore.dig2,4)) &
                                 std_logic_vector(to_unsigned(alarm_time.ore.dig1,4)) &
                                 std_logic_vector(to_unsigned(alarm_time.min.dig2,4)) &
                                 std_logic_vector(to_unsigned(alarm_time.min.dig1,4));
--sec_sec <= std_logic_vector(to_unsigned(0,4)) &
--                                 std_logic_vector(to_unsigned(0,4)) &
--                                 std_logic_vector(to_unsigned(t.sec.dig2,4)) &
--                                 std_logic_vector(to_unsigned(t.sec.dig1,4));

d <= ore_min when (current_state = afis_timp or current_state = set_ore or current_state = set_min) 
  else ore_min_alarm when (current_state = alarm or current_state = set_alarm_ore or current_state = set_alarm_min)
  else (others => '1');

display :  driver7seg port map (
    clk => clk,
    Din => d,
    an => an_int,
    seg => seg,
    dp_in => (others => '0'),
    dp_out => dp, 
    rst => rst);

blink_ora <= '1' when (current_state = set_ore or current_state = set_alarm_ore) else '0';
blink_min <= '1' when (current_state = set_min or current_state = set_alarm_min) else '0';

process(rst, clk)
  variable counter : integer := 0;
begin
  if rst = '1' then
    counter := 0;
    clk1hz <= '0'; 
  elsif rising_edge(clk) then
    if counter = n/2 - 1 then
      counter := 0;
      clk1hz <= not clk1hz;
    else
      counter := counter + 1;
      clk1hz <= clk1hz;
    end if;  
  end if;    
end process;

an(3) <= (an_int(3) or clk1hz) when blink_ora = '1' else an_int(3);
an(2) <= (an_int(2) or clk1hz) when blink_ora = '1' else an_int(2);
an(1) <= (an_int(1) or clk1hz) when blink_min = '1' else an_int(1);
an(0) <= (an_int(0) or clk1hz) when blink_min = '1' else an_int(0);

process(rst, clk)
    begin
        if rst = '1' then
            alarm_out <= '1';
        elsif rising_edge(clk) then
            if t.ore.dig2 = alarm_time.ore.dig2 and
               t.ore.dig1 = alarm_time.ore.dig1 and
               t.min.dig2 = alarm_time.min.dig2 and
               t.min.dig1 = alarm_time.min.dig1 then
                alarm_out <= '0';
            else
                alarm_out <= '1';
            end if;
        end if;
    end process;

end Behavioral;
