import { Phase } from './defs';
import { inSequence } from '../../../util/function-composer';

export const phases: Partial<Record<number, Phase>> = {
  0: {
    // Initial phase: automatically proceed
    async step(driver) {
      await driver.messageDialog({
        message: driver.t('phase0.stepMessage'),
      });
      return 1;
    },
    getStory() {
      return {};
    },
  },
  1: {
    // Phase 1: speak as audience
    async step(driver) {
      await driver.sleep(1000);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase1.stepMessage1'),
      });
      await driver.sleep(3000);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase1.stepMessage2'),
      });
      return 2;
    },
    getStory(driver) {
      return {
        gameInput: {
          // go to next step if user speaks
          onSpeak: inSequence(driver.getSpeakHandler(), driver.step),
        },
      };
    },
  },
  2: {
    // Phase 2: enter the room
    async step(driver) {
      driver.join();
      await driver.sleep(1000);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase2.stepMessage1'),
      });
      await driver.sleep(2500);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase2.stepMessage2'),
      });
      return 3;
    },
    getStory(driver) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
        },
        roomHedaerInput: {
          join: inSequence(driver.getJoinHandler(), driver.step),
        },
      };
    },
  },
  3: {
    async step() {},
    getStory(driver) {
      return {
        roomHedaerInput: {
          join: driver.getJoinHandler(),
          unjoin: driver.getUnjoinHandler(),
        },
      };
    },
  },
};
