import * as React from 'react';
import styled, { withTheme } from '../../../util/styled';
import { Log, autolinkLogType } from '../defs';
import { Rule } from '../../../defs';
import { TranslationFunction, I18nInterp } from '../../../i18n';
import { phone, notPhone } from '../../../common/media';
import { Theme } from '../../../theme';
import { FixedSizeLogRow } from './elements';
import { CommentContent } from './comment';

export interface IPropOneLog {
  /**
   * Translation function,
   * whose default namespace should be 'game_client'.
   */
  t: TranslationFunction;
  theme: Theme;
  /**
   * Class name attached to each log.
   */
  logClass: string;
  /**
   * Whether logs are rendered in fixed-size mode.
   */
  fixedSize: boolean;
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
 * Function to sanitize log text.
 * Removes Unicode bidi characters.
 */
function sanitizeLog(log: string): string {
  return log.replace(/[\u200e\u200f\u202a-\u202e\u2066-\u2069]/g, '');
}

/**
 * A component which shows one log.
 */
class OneLogInner extends React.PureComponent<IPropOneLog, {}> {
  public render() {
    const { t, theme, logClass, fixedSize, log, rule, icons } = this.props;

    const LogLineWrapper = fixedSize ? FixedSizeLogRow : React.Fragment;

    if (log.mode === 'voteresult') {
      // log of vote result table
      const logStyle = computeLogStyle('voteresult', theme);

      return (
        <LogLineWrapper>
          <Icon noName logStyle={logStyle} className={logClass} />
          <Name noName logStyle={logStyle} className={logClass} />
          <Main noName logStyle={logStyle} className={logClass}>
            <LogTable>
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
                      <td>{sanitizeLog(name)}</td>
                      <td>{t('log.voteResult.count', { count: votecount })}</td>
                      <td>→{sanitizeLog(targetname)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </LogTable>
          </Main>
          <Time
            noName
            time={new Date(log.time)}
            logStyle={logStyle}
            className={logClass}
          />
        </LogLineWrapper>
      );
    } else if (log.mode === 'probability_table') {
      // log of probability table for Quantum Werewwolf
      const logStyle = computeLogStyle('probability_table', theme);
      return (
        <LogLineWrapper>
          <Icon noName logStyle={logStyle} className={logClass} />
          <Name noName logStyle={logStyle} className={logClass} />
          <Main noName logStyle={logStyle} className={logClass}>
            <LogTable>
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
                    <ProbabilityTr dead={obj.dead === 1} key={id}>
                      <td>{sanitizeLog(obj.name)}</td>
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
            </LogTable>
          </Main>
          <Time
            noName
            time={new Date(log.time)}
            logStyle={logStyle}
            className={logClass}
          />
        </LogLineWrapper>
      );
    } else if (log.mode === 'poem') {
      const logStyle = computeLogStyle(log.mode, theme);
      const icon = icons[log.userid];
      const noName = icon == null;
      return (
        <LogLineWrapper>
          <Icon noName={noName} logStyle={logStyle} className={logClass} />
          <Name noName={noName} logStyle={logStyle} className={logClass} />
          <Comment noName={noName} logStyle={logStyle} className={logClass}>
            <I18nInterp ns="game_client" k="log.poem.description">
              {{
                name: <b>{log.name}</b>,
                target: <b>{log.target}</b>,
              }}
            </I18nInterp>
            <PoemWrapper>{log.comment}</PoemWrapper>
          </Comment>
          <Time
            noName={noName}
            time={new Date(log.time)}
            logStyle={logStyle}
            className={logClass}
          />
        </LogLineWrapper>
      );
    } else {
      const logStyle = computeLogStyle(log.mode, theme);
      const size = log.mode === 'nextturn' ? undefined : log.size;
      const icon = log.mode === 'nextturn' ? undefined : icons[log.userid];
      const nameText =
        log.mode === 'nextturn' || !log.name
          ? null
          : log.mode === 'monologue' || log.mode === 'heavenmonologue'
            ? t('log.monologue', { name: log.name }) + ':'
            : log.mode === 'will'
              ? t('log.will', { name: log.name }) + ':'
              : log.mode === 'streaming'
                ? t('log.streaming', { name: log.name }) + ':'
                : log.name + ':';
      // Auto-link URLs and room numbers in it.
      const noName = icon == null && !nameText;
      const props = {
        logStyle,
        className: logClass,
        'data-userid': 'userid' in log ? log.userid : undefined,
      };
      const commentProps = {
        size,
        noName,
        ...props,
      };
      // Server's bug? comment may actually be null
      const comment = autolinkLogType.includes(log.mode) ? (
        <Comment {...commentProps}>
          <CommentContent
            comment={log.comment || ''}
            supplement={log.mode === 'nextturn' ? undefined : log.supplement}
          />
        </Comment>
      ) : (
        <Comment {...commentProps}>{sanitizeLog(log.comment)}</Comment>
      );
      return (
        <LogLineWrapper>
          {/* icon */}
          <Icon noName={noName} {...props}>
            {icon != null ? <img src={icon} alt="" /> : null}
          </Icon>
          <Name noName={noName} {...props}>
            {nameText ? sanitizeLog(nameText) : null}
          </Name>
          {comment}
          <Time
            noName={noName}
            time={new Date(log.time)}
            logStyle={logStyle}
            className={logClass}
          />
        </LogLineWrapper>
      );
    }
  }
}

export const OneLog = withTheme(OneLogInner);

interface IPropProbabilityTr {
  dead: boolean;
}
/**
 * Tr element for dead player's probability.
 */
const ProbabilityTr = styled.tr<IPropProbabilityTr>`
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

export interface LogStyle {
  /**
   * background color.
   */
  background: string;
  /**
   * text color.
   */
  color: string;
  /**
   * border color (if exists).
   */
  borderColor: string | null;
  /**
   * Whether text is bold.
   */
  bold?: true;
}
/**
 * ログ種類から色などを計算
 */
export function computeLogStyle(mode: Log['mode'], theme: Theme): LogStyle {
  switch (mode) {
    case 'audience': {
      return {
        background: theme.user.audience.bg,
        color: theme.user.audience.color,
        borderColor: '#eeffee',
      };
    }
    case 'couple': {
      return {
        background: theme.user.couple.bg,
        color: theme.user.couple.color,
        borderColor: '#eeffee',
      };
    }
    case 'day': {
      return {
        background: theme.user.day.bg,
        color: theme.user.day.color,
        borderColor: null,
      };
    }
    case 'fox': {
      return {
        background: theme.user.fox.bg,
        color: theme.user.fox.color,
        borderColor: null,
      };
    }
    case 'gm':
    case 'gmreply': {
      return {
        background: theme.user.gm1.bg,
        color: theme.user.gm1.color,
        borderColor: '#ffa8a8',
      };
    }
    case 'gmaudience':
    case 'gmheaven':
    case 'gmmonologue': {
      return {
        background: theme.user.gm2.bg,
        color: theme.user.gm2.color,
        borderColor: '#ffc68a',
      };
    }
    case 'heaven': {
      return {
        background: theme.user.heaven.bg,
        color: theme.user.heaven.color,
        borderColor: null,
      };
    }
    case 'heavenmonologue': {
      return {
        background: theme.user.heavenmonologue.bg,
        color: theme.user.heavenmonologue.color,
        borderColor: null,
      };
    }
    case 'half-day': {
      return {
        background: theme.user.half_day.bg,
        color: theme.user.half_day.color,
        borderColor: null,
      };
    }
    case 'helperwhisper': {
      return {
        background: theme.user.helperwhisper.bg,
        color: theme.user.helperwhisper.color,
        borderColor: '#e8e000',
      };
    }
    case 'hidden': {
      return {
        background: theme.user.hidden.bg,
        color: theme.user.hidden.color,
        borderColor: null,
      };
    }
    case 'inlog': {
      return {
        background: theme.user.inlog.bg,
        color: theme.user.inlog.color,
        bold: true,
        borderColor: '#00dce8',
      };
    }
    case 'madcouple': {
      return {
        background: theme.user.madcouple.bg,
        color: theme.user.madcouple.color,
        borderColor: '#eeffee',
      };
    }
    case 'monologue': {
      return {
        background: theme.user.monologue.bg,
        color: theme.user.monologue.color,
        borderColor: '#000066',
      };
    }
    case 'nextturn': {
      return {
        background: theme.user.nextturn.bg,
        color: theme.user.nextturn.color,
        bold: true,
        borderColor: '#aaaaaa',
      };
    }
    case 'poem': {
      return {
        background: theme.user.poem.bg,
        color: theme.user.poem.color,
        borderColor: '#e9546b',
      };
    }
    case 'prepare': {
      return {
        background: theme.user.heaven.bg,
        color: theme.user.heaven.color,
        borderColor: '#fffff8',
      };
    }
    case 'probability_table': {
      return {
        background: theme.user.probability_table.bg,
        color: theme.user.probability_table.color,
        borderColor: null,
      };
    }
    case 'streaming': {
      return {
        background: theme.user.streaming.bg,
        color: theme.user.streaming.color,
        borderColor: '#ffc68a',
      };
    }
    case 'system': {
      return {
        background: theme.user.system.bg,
        color: theme.user.system.color,
        bold: true,
        borderColor: '#aaaaaa',
      };
    }
    case 'userinfo': {
      return {
        background: theme.user.userinfo.bg,
        color: theme.user.userinfo.color,
        bold: true,
        borderColor: '#000070',
      };
    }
    case 'voteresult': {
      return {
        background: theme.user.day.bg,
        color: theme.user.day.color,
        borderColor: null,
      };
    }
    case 'voteto': {
      return {
        background: theme.user.voteto.bg,
        color: theme.user.voteto.color,
        bold: true,
        borderColor: '#007000',
      };
    }
    case 'werewolf': {
      return {
        background: theme.user.werewolf.bg,
        color: theme.user.werewolf.color,
        borderColor: '#000066',
      };
    }
    case 'will': {
      return {
        background: theme.user.will.bg,
        color: theme.user.will.color,
        borderColor: null,
      };
    }
    case 'skill':
    case 'emmaskill':
    case 'wolfskill':
    case 'eyeswolfskill':
    case 'draculaskill': {
      return {
        background: theme.user.skill.bg,
        color: theme.user.skill.color,
        bold: true,
        borderColor: '#800000',
      };
    }
  }
}

interface IPropLogPart {
  /**
   * Whether no name is given for this log.
   */
  noName?: boolean;
}

/**
 * Basic style of logcomponents.
 */
const LogPart = styled.div<{
  logStyle: LogStyle;
}>`
  background-color: ${props => props.logStyle.background};
  color: ${props => props.logStyle.color};
  border-top: ${props =>
    props.logStyle.borderColor
      ? `1px dashed ${props.logStyle.borderColor}`
      : 'none'};
  border-bottom: ${props =>
    props.logStyle.borderColor
      ? `1px dashed ${props.logStyle.borderColor}`
      : 'none'};
  font-weight: ${props => (props.logStyle.bold ? 'bold' : 'normal')};
  overflow: hidden;

  line-height: 1;
  word-break: break-all;
  overflow-wrap: break-word;
  word-break: break-word;
  padding: 1px 0;
  font-size: var(--base-font-size);
`;

/**
 * Icon box.
 */
const Icon = styled(LogPart)<IPropLogPart>`
  grid-column: 1;
  min-width: 8px;

  img {
    width: 1em;
    height: 1em;
    vertical-align: bottom;
    ${({ noName }) => String(noName)};
  }

  ${phone<IPropLogPart>`
    grid-row: ${({ noName }) => (noName ? 'span 1' : 'span 2')};
    ${({ noName }) => (noName ? '' : 'border-bottom: none;')}
  `};
`;

/**
 * Username box.
 */
const Name = styled(LogPart)<IPropLogPart>`
  grid-column: 2;
  max-width: 10em;
  overflow: hidden;

  font-weight: bold;
  white-space: nowrap;
  word-wrap: break-word;
  text-align: right;
  ${phone<IPropLogPart>`
    ${({ noName }) => (noName ? 'display: none;' : '')}
    max-width: none;
    text-align: left;
    font-size: calc(0.75 * var(--base-font-size));
    border-bottom: none;
  `};
`;

/**
 * comment (main) box.
 */
const Main = styled(LogPart)<IPropLogPart>`
  grid-column: 3;
  ${phone<IPropLogPart>`
    grid-column: ${({ noName }) => (noName ? '2 / 3' : '2 / 4')};
    ${({ noName }) => (noName ? '' : 'border-top: none;')}
    padding-left: 0.3em;
  `};
`;

interface IPropComment {
  /**
   * Changed size of comment.
   */
  size?: 'big' | 'small';
}

const getFontSize = (size: 'big' | 'small' | undefined) =>
  size === 'big'
    ? 'calc(1.2 * var(--base-font-size))'
    : size === 'small'
      ? 'calc(0.8 * var(--base-font-size))'
      : 'var(--base-font-size)';
const getLineHeight = (size: 'big' | 'small' | undefined) =>
  size === 'big' ? '1' : size === 'small' ? '1.3' : '1';
/**
 * Log comment box.
 */
const Comment = styled(Main)<IPropComment>`
  white-space: pre-wrap;
  font-size: ${({ size }) => getFontSize(size)};
  line-height: ${({ size }) => getLineHeight(size)};
  ${({ size }) => (size === 'big' ? 'font-weight: bold;' : '')};
`;

/**
 * Wrapper of poem in log.
 */
const PoemWrapper = styled.div`
  margin: 0.8em;
`;

interface IPropTime extends IPropLogPart {
  time: Date;
  className?: string;
  logStyle: LogStyle;
}
const TimeInner = ({ time, noName, className, logStyle }: IPropTime) => {
  const year = time.getFullYear();
  const month = ('0' + (time.getMonth() + 1)).slice(-2);
  const day = ('0' + time.getDate()).slice(-2);
  const hour = ('0' + time.getHours()).slice(-2);
  const minute = ('0' + time.getMinutes()).slice(-2);
  const second = ('0' + time.getSeconds()).slice(-2);
  const str = `${year}-${month}-${day} ${hour}:${minute}:${second}`;
  return (
    <LogPart logStyle={logStyle} className={className}>
      <time>{str}</time>
    </LogPart>
  );
};

/**
 * Show time box.
 */
const Time = styled(TimeInner)`
  grid-column: 4;
  display: flex;
  flex-flow: column nowrap;
  justify-content: flex-end;
  padding-left: 2px;
  padding-right: 1ex;
  padding-bottom: 1px;

  white-space: nowrap;
  font-size: xx-small;
  text-align: right;

  ${phone<IPropTime>`
    grid-column: 3;
    font-size: xx-small;
    ${({ noName }) => (noName ? '' : 'border-bottom: none;')}
  `};
  ${notPhone`
    line-height: var(--base-font-size);
  `};
`;

/**
 * Table for logs.
 */
const LogTable = styled.table`
  ${phone`
    font-size: calc(0.88 * var(--base-font-size));
  `};
`;
