import * as React from 'react';
import { autolink } from 'my-autolink';
import styled, { withProps } from '../../util/styled';
import { Log } from '../defs';

export interface IPropOneLog {
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
  rule: Record<string, string>;
}

/**
 * A component which shows one log.
 */
export class OneLog extends React.PureComponent<IPropOneLog, {}> {
  public render() {
    const { log, rule, icons } = this.props;
    if (log.mode === 'voteresult') {
      // log of vote result table
      return (
        <logComponents.voteresult>
          <Icon />
          <Name />
          <table>
            <caption>投票結果</caption>
            <tbody>
              {log.voteresult.map(({ id, name, voteto }) => {
                const votecount = log.tos[id] || 0;
                // Name of vote target
                const vt = log.voteresult.filter(x => x.id === voteto)[0];
                const targetname = (vt ? vt.name : '') || '';
                return (
                  <tr key={id}>
                    <td>{name}</td>
                    <td>{log.tos[id] || 0}票</td>
                    <td>→{targetname}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <Time time={new Date(log.time)} />
        </logComponents.voteresult>
      );
    } else if (log.mode === 'probabilitytable') {
      // log of probability table for Quantum Werewwolf
      return (
        <div>
          <Icon />
          <Name />
          <table>
            <caption>確率表</caption>
            <thead>
              <tr>
                <th>名前</th>
                {rule.quantumwerewolf_diviner === 'on' ? (
                  // Show probability for Diviner and Human separately.
                  <>
                    <th>村人</th>
                    <th>占い師</th>
                  </>
                ) : (
                  <th>人間</th>
                )}
                <th>人狼</th>
                {rule.quantumwerewolf_dead !== 'no' ? <th>死亡</th> : null}
              </tr>
            </thead>
            <tbody>
              {Object.keys(log.probability_table).map(id => {
                const obj = log.probability_table[id];
                return (
                  <ProbabilityTr dead={obj.dead === 1}>
                    <td>{obj.name}</td>
                    <ProbTd prob={obj.Human} />
                    {rule.quantumwerewolf_diviner === 'on' ? (
                      <ProbTd prob={obj.Diviner} />
                    ) : null}
                    <ProbTd prob={obj.Werewolf} />
                    {rule.quantumwerewolf_dead !== 'no' ? (
                      <ProbTd prob={obj.dead} />
                    ) : null}
                  </ProbabilityTr>
                );
              })}
            </tbody>
          </table>
        </div>
      );
    } else {
      const Cmp = logComponents[log.mode];
      const name =
        log.mode === 'nextturn' || !log.name
          ? null
          : log.mode === 'monologue' || log.mode === 'heavenmonologue'
            ? `${log.name}の独り言:`
            : log.name + ':';
      const size = log.mode === 'nextturn' ? undefined : log.size;
      const icon = log.mode === 'nextturn' ? undefined : icons[log.userid];
      // Auto-link URLs and room numbers in it.
      const comment = autolink(
        log.comment,
        [
          'url',
          {
            pattern() {
              return /#(\d+)/g;
            },
            transform(_, num) {
              return {
                href: `/room/#{num}`,
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
      return (
        <Cmp>
          {/* icon */}
          <Icon>{icon != null ? <img src={icon} alt="" /> : null}</Icon>
          <Name>{name}</Name>
          <Comment size={size} dangerouslySetInnerHTML={{ __html: comment }} />
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
  background-color: ${dead => (dead ? 'rgba(0, 0, 0, 0.3)' : 'transparent')};
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
  display: table-row;
  margin: 0;
  width: 100%;
  line-height: 1;
  color: #000000;
`;

/**
 * スキル関係の汎用的なスタイル
 */
const SkillBox = styled(LogBox)`
  background-color: #cc0000;

  color: #ffffff;
  font-weight: bold;

  > * {
    border-top: 1px dashed #800000;
    border-bottom: 1px dashed #800000;
  }
`;

/**
 * GMのスタイル
 */
const GM1Box = styled(LogBox)`
  background-color: #ffd1d1;

  > * {
    border-top: 1px dashed #ffa8a8;
    border-bottom: 1px dashed #ffa8a8;
  }
`;

/**
 * GMのスタイル
 */
const GM2Box = styled(LogBox)`
  background-color: #ffe5c9;

  > * {
    border-top: 1px dashed #ffc68a;
    border-bottom: 1px dashed #ffc68a;
  }
`;

const logComponents: Record<Log['mode'], React.ComponentClass<any>> = {
  audience: styled(LogBox)`
    background-color: #ddffdd;

    > * {
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  couple: styled(LogBox)`
    background-color: #ddddff;

    > * {
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  day: styled(LogBox)`
    background-color: #f0e68c;
  `,
  fox: styled(LogBox)`
    background-color: #934293;
    color: #ffffff;
  `,
  gm: GM1Box,
  gmaudience: GM2Box,
  gmheaven: GM2Box,
  gmmonologue: GM2Box,
  gmreply: GM1Box,
  heaven: styled(LogBox)`
    background-color: rgb(255, 255, 240);

    > * {
      border-top: 1px dashed #fffff8;
      border-bottom: 1px dashed #fffff8;
    }
  `,
  heavenmonologue: styled(LogBox)`
    background-coor: #8888aa;
    color: #ffffff;
  `,
  'half-day': styled(LogBox)`
    background-color: rgb(248, 243, 190);
    color: #999999;
  `,
  helperwhisper: styled(LogBox)`
    background-color: #fff799;

    > * {
      border-top: 1px dashed #e8e000;
      border-bottom: 1px dashed #e8e000;
    }
  `,
  inlog: styled(LogBox)`
    background-color: #a6daff;
    font-weight: bold;

    > * {
      border-top: 1px dashed #00dce8;
      border-bottom: 1px dashed #00dce8;
    }
  `,
  madcouple: styled(LogBox)`
    background-color: #e2e2c0;

    > * {
      border-top: 1px dashed #eeffee;
      border-bottom: 1px dashed #eeffee;
    }
  `,
  monologue: styled(LogBox)`
    background-color: #000044;

    color: #ffffff;

    > * {
      border-top: 1px dashed #000066;
      border-bottom: 1px dashed #000066;
    }
  `,
  nextturn: styled(LogBox)`
    background-color: #eeeeee;
    font-weight: bold;

    > * {
      border-top: 1px dashed #aaaaaa;
      border-bottom: 1px dashed #aaaaaa;
    }
  `,
  prepare: styled(LogBox)`
    background-color: rgb(255, 255, 240);

    > * {
      border-top: 1px dashed #fffff8;
      border-bottom: 1px dashed #fffff8;
    }
  `,
  probabilitytable: LogBox,
  system: styled(LogBox)`
    background-color: #cccccc;
    font-weight: bold;

    > * {
      border-top: 1px dashed #aaaaaa;
      border-bottom: 1px dashed #aaaaaa;
    }
  `,
  userinfo: styled(LogBox)`
    background-color: #0000cc;
    color: #ffffff;
    font-weight: bold;

    > * {
      border-top: 1px dashed #000070;
      border-bottom: 1px dashed #000070;
    }
  `,
  voteresult: styled(LogBox)`
    background-color: #f0e68c;
  `,
  voteto: styled(LogBox)`
    background-color: #009900;
    color: #ffffff;
    font-weight: bold;
    > * {
      border-top: 1px dashed #007000;
      border-bottom: 1px dashed #007000;
    }
  `,
  werewolf: styled(LogBox)`
    background-color: #000044;
    color: #ffffff;
    > * {
      border-top: 1px dashed #000066;
      border-bottom: 1px dashed #000066;
    }
  `,
  will: styled(LogBox)`
    background-color: #222222;
    color: #ffffff;
  `,
  emmaskill: SkillBox,
  eyeswolfskill: SkillBox,
  skill: SkillBox,
  wolfskill: SkillBox,
};

/**
 * Icon box.
 */
const Icon = styled.div`
  display: table-cell;

  img {
    width: 1em;
    height: 1em;
    vertical-align: bottom;
  }
`;

/**
 * Username box.
 */
const Name = styled.div`
  display: table-cell;
  max-width: 10em;
  overflow: hidden;

  font-weight: bold;
  white-space: nowrap;
  word-wrap: break-word;
  text-align: right;
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
const Comment = withProps<IPropComment>()(styled.div)`
  display: table-cell;
  width: 100%;

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
  display: table-cell;
  white-space: nowrap;
  max-width: 22ex;
  font-size: x-small;
  margin-left: 2em;
  line-height: 15px;
`;
