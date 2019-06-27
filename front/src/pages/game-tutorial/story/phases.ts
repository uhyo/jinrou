import { Phase } from './defs';

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
    async step(driver) {},
    getStory() {
      return {
        gameInput: {
          // TODO
        },
      };
    },
  },
};
