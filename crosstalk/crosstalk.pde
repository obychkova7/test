/**
* This processing file runs a graphics frontend for the simulation.
*
* @author  John Lawrence, Jordan Potarf, Andrew Baas
* @version 1.0
* @since   05-07-2017
*/


PrintWriter output;
float[] current, mean, variance, input, pulse, bin;
double[] cellCharges, time;

HScrollbar pulseSizeSlider, timeShiftSlider, crossProbSlider;
ScrollbarLabel pulseSizeLabel, timeShiftLabel, crossProbLabel;
simulator.Simulator sim;

final int SIM_DIAM = 555;

//Simulation constants
final int GRANLARITY  = 3;
final int NUM_CELLS   = 37994;
final int PULSE_LEN   = 100;
final int C_PULSE_LEN = 40;
final double  CROSS_PROB  = .046;
final double  T1 = 0.0001;
final double  T2 = 0.05;
final double  T3 = 0.5;
final double  T4 =  5;
final double  T5 = 0.6;
final double  TRC = 9.0;
final boolean SATURATION  = true;
final boolean CROSSTALK   = true;
final boolean BATCH_JOB   = false;
final int NUM_PHOTONS = 1000;

void setup(){
  simulator.Environment env = new simulator.Environment( GRANLARITY, NUM_CELLS, 
                                PULSE_LEN, C_PULSE_LEN, CROSS_PROB,
                                T1, T2, T3, T4, T5, TRC,
                                SATURATION, CROSSTALK, BATCH_JOB);
  size(1110, 700);
  sim = new simulator.Simulator(NUM_PHOTONS, env);
  time = sim.getTime();
  cellCharges = new double[1000];
  initGraphics();
}


public void initGraphics(){
  // Initialize window
  background(255);
  noStroke();
  
  pulseSizeSlider   = new HScrollbar(0, SIM_DIAM + 32, SIM_DIAM, 16,
                            log(1), log(1000000), log(sim.getNumPhotons()));
  timeShiftSlider   = new HScrollbar(0, SIM_DIAM + 64 , SIM_DIAM, 16,
                            0, sim.getStepsPerPulse() - 1, sim.getTimeShift());
  crossProbSlider   = new HScrollbar(0, SIM_DIAM + 96, SIM_DIAM, 16,
                            log(.0001), log(1),
                            log((float)sim.getCrossProb()));
  pulseSizeLabel  = new ScrollbarLabel(0, SIM_DIAM + 30, SIM_DIAM, 16,
                            "Pulse Size", "photons",
                            exp(pulseSizeSlider.getValue()));
  timeShiftLabel  = new ScrollbarLabel(0, SIM_DIAM + 62, SIM_DIAM, 16,
                            "Time Shift", "nanoseconds",
                            (float)time[(int)timeShiftSlider.getValue()]);
  crossProbLabel  = new ScrollbarLabel(0, SIM_DIAM + 94, SIM_DIAM, 16, "Crosstalk Prob", "%", 100 * (float)sim.getCrossProb());
}

void draw(){
  background(255);
  pulseSizeSlider.update();
  timeShiftSlider.update();
  crossProbSlider.update();
  
  pulseSizeLabel.update(exp(pulseSizeSlider.getValue()));
  timeShiftLabel.update((float)time[(int)timeShiftSlider.getValue()]); 
  crossProbLabel.update(100 * (float)sim.getCrossProb());
  //crossProbLabel.update((float)sim.Landau(2, 0, 20));

  pulseSizeSlider.display();
  timeShiftSlider.display();
  crossProbSlider.display();
  
  pulseSizeLabel.display();
  timeShiftLabel.display();
  crossProbLabel.display();

  updateValues();
  // Update time and environment
  sim.update();

  // Draw things
  drawChip(g, 0, 0, 550);
  Plot.drawPlot(g, sim.getCurrent(), 550, 0, 550, 200, 255, 30, 0);
  float yScale = Plot.drawPlot(g, sim.getPulseShape(), 550, 200, 550, 200, 0, 255, 30);
  Plot.drawPlot(g, sim.getMean(), 550, 200, 550, 200, 0, 30, 255, false, true, yScale);
  Plot.drawPlot(g, sim.getBinning(), 550, 200, 550, 200, 255, 30, 0, false, true, yScale);
  Plot.drawPlot(g, sim.getBinning(), 550, 400, 550, 300, 0, 255, 30);
}

void keyPressed(){
  // Closes the program with Esc key
  if(key == 27){
    exit();         // Stops the program
  }
}

void updateValues(){ 

  if(sim.getTimeShift() != timeShiftSlider.getValue()){
    sim.setTimeShift((int)timeShiftSlider.getValue());
  }
  
  if(sim.getNumPhotons() != (int)exp(pulseSizeSlider.getValue())){
    sim.setNumPhotons((int)exp(pulseSizeSlider.getValue()));
    sim.clearStats();
  }

  if(sim.getCrossProb() != exp(crossProbSlider.getValue())){
    sim.setCrossProb(exp(crossProbSlider.getValue()));
    sim.clearStats();
  }
}

PGraphics drawChip(PGraphics g, int xOr, int yOr, int sideLen){
  int diameter = sim.getDiameter();
  float ratio = sideLen / (float) diameter;
  double[][] charges = sim.getNormCellCharge();
  boolean[][] isPulse = sim.getIsPulse();
  cellCharges[sim.getStep() % cellCharges.length] = charges[diameter / 2][diameter / 2];

  for(int x = 0; x < diameter; x++){
    for(int y = 0; y < diameter; y++){

      float p = (float)charges[x][y];
      if(p > 1){
        p = 1;
      }
      if(isPulse[x][y]){
        g.fill(255 - p*255, 255 - 30 * p, 255 - p * 255);
      }else{
        g.fill(255 - p * 255, 255 - 255 * p, 255 - p * 255);
      }
      g.noStroke();
      g.rect(xOr + x * ratio, yOr + y * ratio, ratio, ratio);
    }
  }

  return g;
}