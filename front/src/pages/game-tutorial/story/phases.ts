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
    // Phase 3: get ready
    async step(driver) {
      await driver.sleep(1000); // TODO: change to 10s
      // add 5 more players
      for (let i = 0; i < 5; i++) {
        const realid = `身代わりくん${i + 2}`;
        driver.addPlayer({
          id: realid,
          realid,
          name: driver.t('guide.name') + (i + 2),
          anonymous: false,
          icon: null,
          winner: null,
          jobname: null,
          dead: false,
          flags: ['ready'],
          emitLog: true,
        });
        await driver.sleep(150);
      }
      return 3;
    },
    getStory(driver) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
        },
        roomHedaerInput: {
          join: driver.getJoinHandler(),
          unjoin: driver.getUnjoinHandler(),
          ready: () => {
            const newReady = driver.ready();
            if (newReady) {
              driver.step();
            } else {
              driver.cancelStep();
            }
          },
          helper: driver.getRejectionHandler(),
        },
      };
    },
  },
};
