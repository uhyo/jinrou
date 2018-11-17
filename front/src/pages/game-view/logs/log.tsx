import * as React from 'react';
import { autolink } from 'my-autolink';
import styled, { withProps } from '../../../util/styled';
import { Log } from '../defs';
import { Rule } from '../../../defs';
import { TranslationFunction } from '../../../i18n';
import { phone } from '../../../common/media';

export interface IPropOneLog {
  /**
   * Translation function,
   * whose default namespace should be 'game_client'.
   */
  t: TranslationFunction;
  /**
   * Class name attached to each log.
   */
  logClass: string;
  /**
   * Log to show.
   */
  log: Log;
  /**
   * Set of icon URLs for users.
   */
  icons: Record<string, string | undefined>;
  /**
   * Current rule setting.
   */
  rule: Rule | undefined;
}

/**
 * A component which shows one log.
 */
export class OneLog extends React.PureComponent<IPropOneLog, {}> {
  public render() {
    const { t, logClass, log, rule, icons } = this.props;
    if (log.mode === 'voteresult') {
      // log of vote result table
      return (
        <logComponents.voteresult className={logClass}>
          <Icon noName />
          <Name noName />
          <Main noName>
            <table>
              {/* Vote result caption */}
              <caption>{t('log.voteResult.caption')}</caption>
              <tbody>
                {log.voteresult.map(({ id, name, voteto }) => {
                  const votecount = log.tos[id] || 0;
                  // Name of vote target
                  const vt = log.voteresult.filter(x => x.id === voteto)[0];
                  const targetname = (vt ? vt.name : '') || '';
                  return (
                    <tr key={id}>
                      <td>{name}</td>
                      <td>{t('log.voteResult.count', { count: votecount })}</td>
                      <td>→{targetname}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Main>
          <Time time={new Date(log.time)} />
        </logComponents.voteresult>
      );
    } else if (log.mode === 'probability_table') {
      // log of probability table for Quantum Werewwolf
      return (
        <logComponents.probability_table className={logClass}>
          <Icon noName />
          <Name noName />
          <Main noName>
            <table>
              {/* Probability table caption */}
              <caption>{t('log.probabilityTable.caption')}</caption>
              <thead>
                <tr>
                  <th>{t('log.probabilityTable.name')}</th>
                  {rule &&
                  rule.rules.get('quantumwerewolf_diviner') === 'on' ? (
                    // Show probability for Diviner and Human separately.
                    <>
                      {/* 村人 */}
                      <th>{t('log.probabilityTable.Villager')}</th>
                      {/* 占い師 */}
                      <th>{t('log.probabilityTable.Diviner')}</th>
                    </>
                  ) : (
                    /* 人間 */
                    <th>{t('log.probabilityTable.Human')}</th>
                  )}
                  {/* 人狼 */}
                  <th>{t('log.probabilityTable.Werewolf')}</th>
                  {rule && rule.rules.get('quantumwerewolf_dead') !== 'no' ? (
                    /* 死亡 */
                    <th>{t('log.probabilityTable.dead')}</th>
                  ) : null}
                </tr>
              </thead>
              <tbody>
                {Object.keys(log.probability_table).map(id => {
                  const obj = log.probability_table[id];
                  return (
                    <ProbabilityTr dead={obj.dead === 1}>
                      <td>{obj.name}</td>
                      <ProbTd prob={obj.Human} />
                      {rule &&
                      rule.rules.get('quantumwerewolf_diviner') === 'on' ? (
                        <ProbTd prob={obj.Diviner} />
                      ) : null}
                      <ProbTd prob={obj.Werewolf} />
                      {rule &&
                      rule.rules.get('quantumwerewolf_dead') !== 'no' ? (
                        <ProbTd prob={obj.dead} />
                      ) : null}
                    </ProbabilityTr>
                  );
                })}
              </tbody>
            </table>
          </Main>
        </logComponents.probability_table>
      );
    } else {
      const Cmp = logComponents[log.mode];
      const size = log.mode === 'nextturn' ? undefined : log.size;
      const icon = log.mode === 'nextturn' ? undefined : icons[log.userid];
      // Auto-link URLs and room numbers in it.
      const comment = autolink(
        // server's bug? comment may actually be null
        log.comment || '',
        [
          'url',
          {
            pattern() {
              return /#(\d+)/g;
            },
            transform(_1, _2, num) {
              return {
                href: `/room/${num}`,
              };
            },
          },
        ],
        {
          url: {
            attributes: {
              rel: 'external',
            },
            text: url => {
              // Convert any room URL to room number syntax.
              const orig = location.origin;
              if (url.slice(0, orig.length) === orig) {
                const r = url.slice(orig.length).match(/^\/room\/(\d+)$/);
                if (r != null) {
                  return `#${r[1]}`;
                }
              }
              return url;
            },
          },
        },
      );
      const nameText =
        log.mode === 'nextturn' || !log.name
          ? null
          : log.mode === 'monologue' || log.mode === 'heavenmonologue'
            ? t('log.monologue', { name: log.name }) + ':'
            : log.name + ':';
      const noName = icon == null && !nameText;
      return (
        <Cmp
          className={logClass}
          data-userid={'userid' in log ? log.userid : undefined}
        >
          {/* icon */}
          <Icon noName={noName}>
            {icon != null ? <img src={icon} alt="" /> : null}
          </Icon>
          <Name noName={noName}>{nameText || null}</Name>
          <Comment
            size={size}
            noName={noName}
            dangerouslySetInnerHTML={{ __html: comment }}
          />
          <Time time={new Date(log.time)} />
        </Cmp>
      );
    }
  }
}

interface IPropProbabilityTr {
  dead: boolean;
}
/**
 * Tr element for dead player's probability.
 */
const ProbabilityTr = withProps<IPropProbabilityTr>()(styled.tr)`
  background-color: ${({ dead }) => (dead ? '#bbbbbb' : 'transparent')};
  color: ${({ dead }) => (dead ? 'black' : 'inherit')};
`;

interface IPropProbTd {
  prob: number;
}
function ProbTd({ prob }: IPropProbTd) {
  if (prob === 1) {
    return (
      <td>
        <b>100%</b>
      </td>
    );
  } else {
    return <td>{(prob * 100).toFixed(2)}%</td>;
  }
}

/**
 * Basic styling of log box.
 */
const LogBox = styled.div`
  display: contents;
  line-height: 1;
  color: #000000;
  word-break: break-all;
  word-break: break-word;

  > * {
    padding: 1px 0;
  }
`;

/**
 * スキル関係の汎用的なスタイル
 */
const SkillBox = styled(LogBox)`
  color: ${props => props.theme.user.skill.color};
  font-weight: bold;

  > * {
    background-color: ${props => props.theme.user.skill.bg};
    border-top: 1px dashed #800000;
    border-bottom: 1px dashed #800000;
  }
`;

/**
 * GMのスタイル
 */
const GM1Box = styled(LogBox)`
  color: ${props => props.theme.user.gm1.color};

  > * {
    background-color: ${props => props.theme.user.gm1.bg};
    border-top: 1px dashed #ffa8a8;
    border-bottom: 1px dashed #ffa8a8;
  }
`;

/**
 * GMのスタイル
 */
const GM2Box = styled(LogBox)`
  color: ${props => props.theme.user.gm2.color};

  > * {
    background-color: ${props => props.theme.user.gm2.bg};
    border-top: 1px dashed #ffc68a;
    border-bottom: 1px dashed #ffc68a;
  }
`;

const logComponents: Record<Log['mode'], React.ComponentClass<any>> = {
  audience: styled(LogBox)`
    color: ${props => props.theme.user.audience.color};

    > * {
      background-color: ${props => props.theme.user.audience.bg};
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  couple: styled(LogBox)`
    color: ${props => props.theme.user.couple.color};

    > * {
      background-color: ${props => props.theme.user.couple.bg};
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  day: styled(LogBox)`
    color: ${props => props.theme.user.day.color};

    > * {
      background-color: ${props => props.theme.user.day.bg};
    }
  `,
  fox: styled(LogBox)`
    color: ${props => props.theme.user.fox.color};

    > * {
      background-color: ${props => props.theme.user.fox.bg};
    }
  `,
  gm: GM1Box,
  gmaudience: GM2Box,
  gmheaven: GM2Box,
  gmmonologue: GM2Box,
  gmreply: GM1Box,
  heaven: styled(LogBox)`
    color: ${props => props.theme.user.heaven.color};

    > * {
      background-color: ${props => props.theme.user.heaven.bg};
    }
  `,
  heavenmonologue: styled(LogBox)`
    color: ${props => props.theme.user.heavenmonologue.color};
    > * {
      background-color: ${props => props.theme.user.heavenmonologue.bg};
    }
  `,
  'half-day': styled(LogBox)`
    color: ${props => props.theme.user.half_day.color};

    > * {
      background-color: ${props => props.theme.user.half_day.bg};
    }
  `,
  helperwhisper: styled(LogBox)`
    color: ${props => props.theme.user.helperwhisper.color};

    > * {
      background-color: ${props => props.theme.user.helperwhisper.bg};
      border-top: 1px dashed #e8e000;
      border-bottom: 1px dashed #e8e000;
    }
  `,
  inlog: styled(LogBox)`
    color: ${props => props.theme.user.inlog.color};
    font-weight: bold;

    > * {
      background-color: ${props => props.theme.user.inlog.bg};
      border-top: 1px dashed #00dce8;
      border-bottom: 1px dashed #00dce8;
    }
  `,
  madcouple: styled(LogBox)`
    color: ${props => props.theme.user.madcouple.color};

    > * {
      background-color: ${props => props.theme.user.madcouple.bg};
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  monologue: styled(LogBox)`
    color: ${props => props.theme.user.monologue.color};

    > * {
      background-color: ${props => props.theme.user.monologue.bg};
      border-top: 1px dashed #000066;
      border-bottom: 1px dashed #000066;
    }
  `,
  nextturn: styled(LogBox)`
    color: ${props => props.theme.user.nextturn.color};
    font-weight: bold;

    > * {
      background-color: ${props => props.theme.user.nextturn.bg};
      border-top: 1px dashed #aaaaaa;
      border-bottom: 1px dashed #aaaaaa;
    }
  `,
  prepare: styled(LogBox)`
    color: ${props => props.theme.user.heaven.color};

    > * {
      background-color: ${props => props.theme.user.heaven.bg};
      border-top: 1px dashed #fffff8;
      border-bottom: 1px dashed #fffff8;
    }
  `,
  probability_table: styled(LogBox)`
    color: ${props => props.theme.user.probability_table.color};

    > * {
      background-color: ${props => props.theme.user.probability_table.bg};
    }
  `,
  system: styled(LogBox)`
    color: ${props => props.theme.user.system.color};
    font-weight: bold;

    > * {
      background-color: ${props => props.theme.user.system.bg};
      border-top: 1px dashed #aaaaaa;
      border-bottom: 1px dashed #aaaaaa;
    }
  `,
  userinfo: styled(LogBox)`
    color: ${props => props.theme.user.userinfo.color};
    font-weight: bold;

    > * {
      background-color: ${props => props.theme.user.userinfo.bg};
      border-top: 1px dashed #000070;
      border-bottom: 1px dashed #000070;
    }
  `,
  voteresult: styled(LogBox)`
    color: ${props => props.theme.user.day.color};

    > * {
      background-color: ${props => props.theme.user.day.bg};
    }
  `,
  voteto: styled(LogBox)`
    color: ${props => props.theme.user.voteto.color};
    font-weight: bold;

    > * {
      background-color: ${props => props.theme.user.voteto.bg};
      border-top: 1px dashed #007000;
      border-bottom: 1px dashed #007000;
    }
  `,
  werewolf: styled(LogBox)`
    color: ${props => props.theme.user.werewolf.color};

    > * {
      background-color: ${props => props.theme.user.werewolf.bg};
      border-top: 1px dashed #000066;
      border-bottom: 1px dashed #000066;
    }
  `,
  will: styled(LogBox)`
    color: ${props => props.theme.user.will.color};

    > * {
      background-color: ${props => props.theme.user.will.bg};
    }
  `,
  emmaskill: SkillBox,
  eyeswolfskill: SkillBox,
  skill: SkillBox,
  wolfskill: SkillBox,
};

interface IPropLogPart {
  /**
   * Whether no name is given for this log.
   */
  noName?: boolean;
}

/**
 * Icon box.
 */
const Icon = withProps<IPropLogPart>()(styled.div)`
  grid-column: 1;
  min-width: 8px;

  img {
    width: 1em;
    height: 1em;
    vertical-align: bottom;
  }

  ${phone`
    grid-row: ${({ noName }) => (noName ? 'span 1' : 'span 2')};
    border-bottom: none;
  `};
`;

/**
 * Username box.
 */
const Name = withProps<IPropLogPart>()(styled.div)`
  grid-column: 2;
  max-width: 10em;
  overflow: hidden;

  font-weight: bold;
  white-space: nowrap;
  word-wrap: break-word;
  text-align: right;
  ${phone`
    ${({ noName }) => (noName ? 'display: none;' : '')}
    max-width: none;
    text-align: left;
    font-size: small;
    border-bottom: none;
  `};
`;

/**
 * comment (main) box.
 */
const Main = withProps<IPropLogPart>()(styled.div)`
  grid-column: 3;
  ${phone`
    grid-column: ${({ noName }) => (noName ? '2 / 3' : '2 / 4')};
    border-top: none;
    padding-left: 0.3em;
  `};
`;

interface IPropComment {
  /**
   * Changed size of comment.
   */
  size?: 'big' | 'small';
}
/**
 * Log comment box.
 */
const Comment = withProps<IPropComment>()(styled(Main))`
  white-space: pre-wrap;
  font-size: ${({ size }) =>
    size === 'big' ? 'larger' : size === 'small' ? 'smaller' : 'medium'};
  font-weight: ${({ size }) => (size === 'big' ? 'bold' : 'inherit')};
`;

interface IPropTime {
  time: Date;
  className?: string;
}
const TimeInner = ({ time, className }: IPropTime) => {
  const year = time.getFullYear();
  const month = ('0' + (time.getMonth() + 1)).slice(-2);
  const day = ('0' + time.getDate()).slice(-2);
  const hour = ('0' + time.getHours()).slice(-2);
  const minute = ('0' + time.getMinutes()).slice(-2);
  const second = ('0' + time.getSeconds()).slice(-2);
  const str = `${year}-${month}-${day} ${hour}:${minute}:${second}`;
  return <time className={className}>{str}</time>;
};

/**
 * Show time box.
 */
const Time = styled(TimeInner)`
  grid-column: 4;
  white-space: nowrap;
  font-size: xx-small;
  padding-left: 2px;
  line-height: 15px;
  text-align: right;
  padding-right: 1ex;

  ${phone`
    grid-column: 3;
    font-size: xx-small;
    border-bottom: none;
  `};
`;
