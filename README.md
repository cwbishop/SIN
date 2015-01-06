Speech In Noise (SIN) Software Package
===

Overview
--------

SIN is a software package that has been used to run many behavioral tests, including basic psychoacoustic and highly demanding audiological paradigms, at multiple testing sites and Univerisities. For example, SIN has been used to do everything from basic playback and recording to administering audiovisual clinical tests like the Multimodal Lexical Sentence Test (MLST) developed by Karen Kirk and colleagues at the University of Iowa (http://www.flintbox.com/public/project/23463). 

The package is written primarily in MATLAB and leverages PsychToolBox (http://psychtoolbox.org/) to create a uniform testing environment with virtually any hardware setup. 

Why Use SIN?
------

Motivation and Development Goals
------

SIN was initially developed for a multi-site project between the University of Washington and University of Iowa. The project required experimenters to administer approximately 30 - 40 individual audio or audiovisual tasks in a highly reproducible way with minimal inter-experimenter variance across 250 patients. While there were procedures and, in rare instances, applications to administer individual tests, many of these procedures require the experimenter to make real-time decisions; thus, mistakes are likely, difficult to recover from, and, more importantly, often go unnoticed. 

Thus, the goal SIN was to create a flexible and uniform platform upon which all tests could be administered, scored, and stored with as much automaticity as possible.

Design
------

SIN is comprised of four major types of functions.

1. _Players_
  + A player generally accepts a set of stimuli and parameters to configure playback, recording, modification checks, modifiers, etc. 
2. _Modification Checks_
  + Modification checks are generally used to gather some form of information and convert that information into a set of discrete actions. For example, a mod check may send a actionable modification code to one or more modifiers in response to a button press.
3. _Modifiers_
  + Modifiers can modify anything about the player, player parameters, or the playback/recording data.
  + Modifiers typically wait for a specific modification code before taking an action. For instance, the up-and-coming playback signal may be scaled in response to experimenter pressing a "louder" button during the mod check stage.
  + Other modifiers may provide their own conditional checks and determine actionable events in lieu of a modification check. In these cases, there is little difference between a modification check and a modifier except perhaps when and how it is executed within the player
4. _Analyses_
  + Analyses accept the returned data structure(s) from a player and analyze the data in some way. The nature of the analysis will depend on the experimenter's desired metrics. 
 
  


Installation Dependencies
------

Step-by-step installation instructions of all core SIN software and dependencies are available at the link below. If you have any difficulty with insallation, please contact Chris Bishop at cwbishop@uw.edu.

http://www.evernote.com/l/AWGfHzxf2PNGJ6j1YIb7q57vsgzQtCPZ56c/

Available Tests
------

1. _Hearing in Noise Test (HINT)_
2. _Perceptual Performance Test_
2. _Multimodal Lexical Sentence Test (MLST)_
3. _Reading Span_
3. _Word Span_
4. _Acceptable Noise Level_


Developing New Tests
------

Applications
------

Function List
------

_Core_

_Stimulus Generation_

_Stimulus Calibration_

_Modification Checks_

_Modifiers_

_Analysis_

_Signal Processing_

_Behavioral Algorithms_

_Other_
