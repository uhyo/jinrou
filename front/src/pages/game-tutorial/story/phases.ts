import { Phase } from './defs';
import { inSequence } from '../../../util/function-composer';
import { humanRole, divinerRole } from './roleInfo';

export const phases: Partial<Record<number, Phase>> = {
  0: {
    // Initial phase: automatically proceed
    async step(driver) {
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase0.stepMessage'),
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
        roomHedaerInput: {
          join: driver.getRejectionHandler(),
        },
      };
    },
  },
  2: {
    // Phase 2: enter the room
    async step(driver) {
      driver.join();
      await driver.sleep(6e3);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase2.stepMessage1'),
      });
      await driver.sleep(5e3);
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
      driver.ready(true);
      await driver.sleep(10e3);
      // add 5 more players
      for (let i = 0; i < 5; i++) {
        const realid = `身代わりくん${i + 2}`;
        driver.addPlayer({
          id: realid,
          realid,
          name: driver.t(`guide.npc${i + 1}`),
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
      return 4;
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
  4: {
    // Phase 4: automatically start game
    init(driver) {
      driver.step();
    },
    async step(driver) {
      await driver.sleep(600);
      driver.addLog({
        mode: 'prepare',
        name: driver.t('guide.name'),
        comment: driver.t('phase4.stepMessage1'),
      });
      await driver.sleep(5000);
      driver.setRoleInfo(humanRole(driver.t, true));
      driver.changeGamePhase({
        day: 1,
        night: true,
        gameStart: true,
        timer: {
          enabled: true,
          name: driver.t('game:phase.night'),
          target: Date.now() + 30000,
        },
      });
      return 5;
    },
    getStory(driver) {
      return {
        roomHedaerInput: {
          ready: () => {
            const newReady = driver.ready();
            if (!newReady) {
              driver.cancelStep();
            } else {
              driver.step();
            }
          },
        },
      };
    },
  },
  5: {
    // Phase 5: game stared
    init(driver) {
      driver.step();
    },
    async step(driver) {
      await driver.sleep(3e3);
      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase5.stepMessage1'),
      });
      await driver.sleep(27e3);
      driver.killPlayer('身代わりくん', 'normal');
      driver.changeGamePhase({
        day: 2,
        night: false,
        timer: {
          enabled: true,
          name: driver.t('game:phase.day'),
          target: Date.now() + 330e3,
        },
      });
      driver.setRoleInfo(humanRole(driver.t, false));
      driver.openForm({
        type: '_day',
        objid: 'Human_day',
        formType: 'required',
      });
      await driver.sleep(2e3);
      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase5.stepMessage2'),
      });
      await driver.sleep(1e3);
      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase5.stepMessage3'),
      });
      return 6;
    },
    getStory(driver) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
        },
      };
    },
  },
  6: {
    // Phase 6: during day 2
    async step(driver, storage) {
      // voted
      if (storage.day2DayTarget == null) {
        return;
      }
      if (!driver.voteTo(storage.day2DayTarget)) {
        return;
      }
      driver.closeForm('Human_day');
      await driver.sleep(4e3);

      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase6.stepMessage1'),
      });

      await driver.sleep(7e3);
      driver.execute(storage.day2DayTarget, storage.day2DayTarget);
      driver.killPlayer(storage.day2DayTarget, 'punish');
      driver.changeGamePhase({
        day: 2,
        night: true,
        timer: {
          enabled: true,
          name: driver.t('game:phase.night'),
          target: Date.now() + 150e3,
        },
      });
      driver.setRoleInfo(divinerRole(driver.t, true));
      driver.openForm({
        type: 'Diviner',
        objid: 'Diviner_night',
        formType: 'required',
      });
      return 7;
    },
    getStory(driver, storage) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
          onJobQuery: query => {
            console.log(query);
            storage.day2DayTarget = query.target;
            driver.step();
          },
        },
      };
    },
  },
  7: {
    // Phase 7: transition to day 2 night
    init(driver) {
      driver.step();
    },
    async step(driver) {
      await driver.sleep(3e3);
      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase7.stepMessage1'),
      });
      await driver.sleep(6e3);
      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase7.stepMessage2'),
      });
      return 8;
    },
    getStory(driver) {
      return {};
    },
  },
  8: {
    // Phase 8: during night 2
    async step(driver, storage) {
      if (storage.day2NightTarget == null) {
        return;
      }
      driver.closeForm('Diviner_night');
      const divinerDriver = driver.divinerSkillTo(storage.day2NightTarget);

      divinerDriver.select();

      await driver.sleep(1e3);

      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase8.stepMessage1'),
      });

      await driver.sleep(8e3);
      // decide today's werewolf target
      storage.day2NightVictim = driver.randomAlivePlayer();
      driver.changeGamePhase({
        day: 3,
        night: false,
        timer: {
          enabled: true,
          name: driver.t('game:phase.day'),
          target: Date.now() + 330e3,
        },
      });
      if (storage.day2NightVictim != null) {
        driver.killPlayer(storage.day2NightVictim, 'normal');
      }
      divinerDriver.result();

      driver.setRoleInfo(divinerRole(driver.t, false));
      driver.openForm({
        type: '_day',
        objid: 'Human_day',
        formType: 'required',
      });

      await driver.sleep(2e3);

      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase8.stepMessage2'),
      });

      return 9;
    },
    getStory(driver, storage) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
          onJobQuery: query => {
            console.log(query);
            storage.day2NightTarget = query.target;
            driver.step();
          },
        },
      };
    },
  },
  9: {
    async step(driver, storage) {
      if (storage.day3DayTarget == null) {
        return;
      }
      if (!driver.voteTo(storage.day3DayTarget)) {
        return;
      }
      driver.closeForm('Human_day');
      await driver.sleep(4e3);

      // 2日目の占い先は白なので処刑者から除外
      storage.day3DayVictim = driver.randomAlivePlayer(
        storage.day2NightTarget || undefined,
      );

      if (storage.day3DayVictim != null) {
        driver.execute(storage.day3DayVictim, storage.day3DayTarget);
        driver.killPlayer(storage.day3DayVictim, 'punish');
      }
      driver.endGame({
        loser: storage.day3DayVictim,
      });
      await driver.sleep(3e3);

      driver.addLog({
        mode: 'gm',
        name: driver.t('roles:jobname.GameMaster'),
        comment: driver.t('phase9.stepMessage1'),
      });

      return 10;
    },
    getStory(driver, storage) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
          onJobQuery: query => {
            storage.day3DayTarget = query.target;
            driver.step();
          },
        },
      };
    },
  },
  10: {
    isFinished: true,
    async step() {},
    getStory(driver) {
      return {
        gameInput: {
          onSpeak: driver.getSpeakHandler(),
        },
      };
    },
  },
};
