% Run GUI
function RunMicroSeimsicGUI

  set(0, 'DefaultAxesFontSize', 10);

  fig = figure('Position',[100 150 1600 800],'Name','MicroSeismicGUI',...
              'MenuBar','none','NumberTitle','off');

  % Models
  pickPath = 'picks/picks.txt';
  miniSeedData = MiniSeedData;
  pickData = PickData(pickPath);

  % Views
  EventView(miniSeedData,pickData,fig);
  StationView(miniSeedData,pickData,fig);

  spectrumView = SpectrumView(miniSeedData,pickData,fig);
  hodogramView = HodogramView(miniSeedData,pickData,fig);

  % Controller
  Controller(miniSeedData,pickData,spectrumView,hodogramView,fig);

end