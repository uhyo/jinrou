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
};
