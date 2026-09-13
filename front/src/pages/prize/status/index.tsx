import * as React from 'react';
import { observer } from 'mobx-react';
import { bind } from 'bind-decorator';
import memoizeOne from 'memoize-one';
import { i18n } from '../../../i18n';
import { getPrizeStatus } from '../../../api/prize-status';
import { LinkLikeButton } from '../../../common/button';
import { PrizeStore } from '..';
import { PrizeStatusRow, PrizeStatusSeries } from '../defs';
import {
  StatusAchievedBadge,
  StatusCondition,
  StatusDescription,
  StatusGroup,
  StatusGroupSummary,
  StatusIndent,
  StatusJobGroup,
  StatusKindLabel,
  StatusList,
  StatusPrizeName,
  StatusProgressBar,
  StatusProgressText,
  StatusRowItem,
  StatusSection,
  StatusSeries,
  StatusSeriesTitle,
  StatusTitle,
} from './elements';

/**
 * Sections of the status display, in display order.
 * "winlose" is a merged tree of wincount/losecount rows:
 * team (阵营) -> job (职业) -> win/lose prizes.
 */
type StatusSeriesView = 'winlose' | 'winteamcount' | 'counter' | 'ownprizes';

const statusSeriesOrder: StatusSeriesView[] = [
  'winlose',
  'winteamcount',
  'counter',
  'ownprizes',
];

/**
 * Display order of teams for the win/lose tree.
 * Keys of teams in client/code/shared/game.coffee.
 */
const winLoseTeamOrder: string[] = [
  'Human',
  'Werewolf',
  'Fox',
  'Devil',
  'Friend',
  'Vampire',
  'Cult',
  'Raven',
  'Hooligan',
  'Duel',
  'Lorelei',
  'Others',
  'Neet',
];

/**
 * One job node of the win/lose tree.
 */
interface WinLoseJobNode {
  key: string;
  label: string;
  win: PrizeStatusRow[];
  lose: PrizeStatusRow[];
  achieved: number;
  total: number;
}

/**
 * One team node of the win/lose tree.
 */
interface WinLoseTeamNode {
  key: string;
  label: string;
  /**
   * For the "all" team, rows are attached directly without a job layer.
   */
  jobs: WinLoseJobNode[];
  allWin: PrizeStatusRow[];
  allLose: PrizeStatusRow[];
  achieved: number;
  total: number;
}

/**
 * Build the team -> job -> win/lose tree from wincount/losecount rows.
 */
function buildWinLoseTree(
  i18n: i18n,
  rows: PrizeStatusRow[],
): WinLoseTeamNode[] {
  const map = new Map<string, WinLoseTeamNode>();
  for (const row of rows) {
    const teamKey = row.team == null ? 'Others' : row.team;
    let team = map.get(teamKey);
    if (team == null) {
      team = {
        key: teamKey,
        label:
          teamKey === 'all' ? i18n.t('status.jobAll') : row.teamName || teamKey,
        jobs: [],
        allWin: [],
        allLose: [],
        achieved: 0,
        total: 0,
      };
      map.set(teamKey, team);
    }
    team.total += 1;
    if (row.achieved) {
      team.achieved += 1;
    }
    if (teamKey === 'all') {
      if (row.series === 'wincount') {
        team.allWin.push(row);
      } else {
        team.allLose.push(row);
      }
      continue;
    }
    let job = team.jobs.find(j => j.key === row.kind);
    if (job == null) {
      job = {
        key: row.kind,
        label: row.jobName || row.kind,
        win: [],
        lose: [],
        achieved: 0,
        total: 0,
      };
      team.jobs.push(job);
    }
    job.total += 1;
    if (row.achieved) {
      job.achieved += 1;
    }
    if (row.series === 'wincount') {
      job.win.push(row);
    } else {
      job.lose.push(row);
    }
  }
  const byRequired = (a: PrizeStatusRow, b: PrizeStatusRow): number =>
    a.required - b.required || a.id.localeCompare(b.id);
  for (const team of map.values()) {
    team.allWin.sort(byRequired);
    team.allLose.sort(byRequired);
    for (const job of team.jobs) {
      job.win.sort(byRequired);
      job.lose.sort(byRequired);
    }
  }
  const ordered: WinLoseTeamNode[] = [];
  const allTeam = map.get('all');
  if (allTeam != null) {
    ordered.push(allTeam);
  }
  for (const key of winLoseTeamOrder) {
    const team = map.get(key);
    if (team != null) {
      ordered.push(team);
    }
  }
  for (const key of map.keys()) {
    if (key !== 'all' && winLoseTeamOrder.indexOf(key) < 0) {
      const team = map.get(key);
      if (team != null) {
        ordered.push(team);
      }
    }
  }
  return ordered;
}

/**
 * Build condition text of a prize.
 */
function prizeCondition(i18n: i18n, row: PrizeStatusRow): string {
  // NOTE: i18next types require `count` to be a number.
  const count = row.required;
  switch (row.series) {
    case 'wincount':
      return row.kind === 'all'
        ? i18n.t('status.condition.wincountAll', { count })
        : i18n.t('status.condition.wincount', {
            job: row.jobName || row.kind,
            count,
          });
    case 'losecount':
      return row.kind === 'all'
        ? i18n.t('status.condition.losecountAll', { count })
        : i18n.t('status.condition.losecount', {
            job: row.jobName || row.kind,
            count,
          });
    case 'winteamcount':
      return i18n.t('status.condition.winteamcount', {
        team: row.teamName || row.kind,
        count,
      });
    case 'counter':
      return i18n.t('status.condition.counter', {
        description: i18n.t(`status.counterDescription.${row.kind}`, {
          defaultValue: row.kind,
        }),
        count,
      });
    case 'ownprizes':
      return i18n.t('status.condition.ownprizes', { count });
  }
}

/**
 * Label of a sub-group of a series.
 */
function groupLabel(
  i18n: i18n,
  series: PrizeStatusSeries,
  rows: PrizeStatusRow[],
): string {
  if (rows.length === 0) {
    return '';
  }
  const row = rows[0];
  switch (series) {
    case 'wincount':
    case 'losecount':
      return row.kind === 'all'
        ? i18n.t('status.jobAll')
        : row.jobName || row.kind;
    case 'winteamcount':
      return row.teamName || row.kind;
    case 'counter':
      return i18n.t(`status.counterDescription.${row.kind}`, {
        defaultValue: row.kind,
      });
    case 'ownprizes':
      return '';
  }
}

/**
 * Group rows by kind, sorting each group by required count.
 */
function groupRows(rows: PrizeStatusRow[]): PrizeStatusRow[][] {
  const map = new Map<string, PrizeStatusRow[]>();
  for (const row of rows) {
    let group = map.get(row.kind);
    if (group == null) {
      group = [];
      map.set(row.kind, group);
    }
    group.push(row);
  }
  const result: PrizeStatusRow[][] = [];
  for (const group of map.values()) {
    group.sort((a, b) => a.required - b.required || a.id.localeCompare(b.id));
    result.push(group);
  }
  return result;
}

/**
 * Display data of one series, computed once per status update.
 */
interface PreparedSeries {
  /**
   * Rows of the series.
   */
  rows: PrizeStatusRow[];
  /**
   * Rows grouped by kind, each group sorted by required count.
   * Undefined for 'winlose' (rendered as a tree) and 'ownprizes'
   * (no meaningful sub-groups).
   */
  groups?: PrizeStatusRow[][];
}

/**
 * Display data of all series, keyed like StatusSeriesView.
 */
interface PreparedSeriesData {
  winlose: PreparedSeries;
  winteamcount: PreparedSeries;
  counter: PreparedSeries;
  ownprizes: PreparedSeries;
}

export interface IPropPrizeStatus {
  i18n: i18n;
  store: PrizeStore;
}

/**
 * Show prize status (称号图鉴): conditions and progress of all prizes.
 */
@observer
export class PrizeStatus extends React.Component<IPropPrizeStatus, {}> {
  /**
   * Memoized preparation of display data of all series.
   */
  private prepareData = memoizeOne(
    (status: PrizeStatusRow[]): PreparedSeriesData => {
      const winteamcount = status.filter(row => row.series === 'winteamcount');
      const counter = status.filter(row => row.series === 'counter');
      return {
        winlose: {
          rows: status.filter(
            row => row.series === 'wincount' || row.series === 'losecount',
          ),
        },
        winteamcount: { rows: winteamcount, groups: groupRows(winteamcount) },
        counter: { rows: counter, groups: groupRows(counter) },
        ownprizes: {
          rows: status.filter(row => row.series === 'ownprizes'),
        },
      };
    },
  );

  /**
   * Memoized construction of the win/lose tree.
   */
  private winLoseTree = memoizeOne(buildWinLoseTree);

  public render() {
    const { i18n, store } = this.props;
    const prepared = this.prepareData(store.status);
    return (
      <StatusSection>
        <StatusTitle>{i18n.t('status.title')}</StatusTitle>
        <p>
          <LinkLikeButton onClick={this.handleShrink}>
            {store.statusShrinked
              ? i18n.t('status.openLabel')
              : i18n.t('status.closeLabel')}
          </LinkLikeButton>
        </p>
        {store.statusShrinked ? null : (
          <>
            <StatusDescription>
              {i18n.t('status.description')}
            </StatusDescription>
            {statusSeriesOrder.map(series => {
              const { rows } = prepared[series];
              if (rows.length === 0) {
                return null;
              }
              const achieved = rows.filter(row => row.achieved).length;
              return (
                <StatusSeries key={series}>
                  <StatusSeriesTitle>
                    {i18n.t(`status.series.${series}`)}（
                    {i18n.t('status.groupCount', {
                      achieved: String(achieved),
                      total: String(rows.length),
                    })}
                    ）
                  </StatusSeriesTitle>
                  {this.renderGroups(series, prepared)}
                </StatusSeries>
              );
            })}
          </>
        )}
      </StatusSection>
    );
  }

  /**
   * Render sub-groups of a series.
   */
  protected renderGroups(
    series: StatusSeriesView,
    prepared: PreparedSeriesData,
  ): React.ReactNode {
    const { i18n } = this.props;
    const { rows, groups } = prepared[series];
    // ownprizes has no meaningful sub-groups.
    if (series === 'ownprizes') {
      return this.renderRows(rows);
    }
    // Win/lose counts are rendered as a team -> job -> win/lose tree.
    if (series === 'winlose') {
      return this.renderWinLose(rows);
    }
    // groups is defined for winteamcount / counter.
    if (groups == null) {
      return null;
    }
    return (
      <div>
        {groups.map(group => {
          const label = groupLabel(i18n, series, group);
          const achieved = group.filter(row => row.achieved).length;
          return (
            <StatusGroup key={group[0].kind}>
              <StatusGroupSummary>
                {label}（
                {i18n.t('status.groupCount', {
                  achieved: String(achieved),
                  total: String(group.length),
                })}
                ）
              </StatusGroupSummary>
              {this.renderRows(group)}
            </StatusGroup>
          );
        })}
      </div>
    );
  }

  /**
   * Render the team -> job -> win/lose tree (wincount/losecount rows).
   */
  protected renderWinLose(rows: PrizeStatusRow[]): React.ReactNode {
    const { i18n } = this.props;
    const teams = this.winLoseTree(i18n, rows);
    return (
      <div>
        {teams.map(team => (
          <StatusGroup key={team.key}>
            <StatusGroupSummary>
              {team.label}（
              {i18n.t('status.groupCount', {
                achieved: String(team.achieved),
                total: String(team.total),
              })}
              ）
            </StatusGroupSummary>
            {team.key === 'all' ? (
              <StatusIndent>
                {this.renderKindSection(team.allWin)}
                {this.renderKindSection(team.allLose)}
              </StatusIndent>
            ) : (
              team.jobs.map(job => (
                <StatusJobGroup key={job.key}>
                  <StatusGroupSummary>
                    {job.label}（
                    {i18n.t('status.groupCount', {
                      achieved: String(job.achieved),
                      total: String(job.total),
                    })}
                    ）
                  </StatusGroupSummary>
                  {this.renderKindSection(job.win)}
                  {this.renderKindSection(job.lose)}
                </StatusJobGroup>
              ))
            )}
          </StatusGroup>
        ))}
      </div>
    );
  }

  /**
   * Render a win / lose subsection inside a job group.
   */
  protected renderKindSection(rows: PrizeStatusRow[]): React.ReactNode {
    const { i18n } = this.props;
    if (rows.length === 0) {
      return null;
    }
    const title =
      rows[0].series === 'wincount'
        ? i18n.t('status.winTitle')
        : i18n.t('status.loseTitle');
    return (
      <div>
        <StatusKindLabel>{title}</StatusKindLabel>
        {this.renderRows(rows)}
      </div>
    );
  }

  /**
   * Render prize status rows.
   */
  protected renderRows(rows: PrizeStatusRow[]): React.ReactNode {
    const { i18n } = this.props;
    return (
      <StatusList>
        {rows.map(row => {
          const percent =
            row.required === 0 ? 100 : (row.current / row.required) * 100;
          return (
            <StatusRowItem key={row.id}>
              <StatusPrizeName>{row.name}</StatusPrizeName>
              <StatusCondition>{prizeCondition(i18n, row)}</StatusCondition>
              <StatusProgressBar percent={percent} />
              <StatusProgressText>
                {i18n.t('status.progress', {
                  current: String(row.current),
                  required: String(row.required),
                })}
              </StatusProgressText>
              <StatusAchievedBadge achieved={row.achieved}>
                {row.achieved
                  ? i18n.t('status.achieved')
                  : i18n.t('status.notAchieved')}
              </StatusAchievedBadge>
            </StatusRowItem>
          );
        })}
      </StatusList>
    );
  }

  @bind
  protected handleShrink() {
    const { store } = this.props;
    if (store.statusShrinked && !store.statusLoaded) {
      // The status section is expanded first: fetch the progress lazily.
      getPrizeStatus().then(status => {
        if (status != null) {
          store.setStatus(status);
        }
      });
    }
    store.setStatusShrinked(!store.statusShrinked);
  }
}
