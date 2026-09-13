import styled from '../../../util/styled';
import {
  activeButtonColor,
  helperTextColor,
  lightBorderColor,
  noColor,
  yesColor,
} from '../../../common/color';
import { phone } from '../../../common/media';

/**
 * Wrapper of the prize status (称号图鉴) section.
 */
export const StatusSection = styled.section`
  margin: 1.2em 0;
  padding: 0 20px;
  border: 1px solid ${lightBorderColor};
`;

/**
 * Title of the status section.
 */
export const StatusTitle = styled.h2`
  font-size: 1.2em;
`;

/**
 * Description of the status section.
 */
export const StatusDescription = styled.p`
  font-size: 0.85em;
  color: ${helperTextColor};
  margin: 0.4em 0;
`;

/**
 * Wrapper of one series.
 */
export const StatusSeries = styled.section`
  margin: 0.8em 0;
`;

/**
 * Title of one series.
 */
export const StatusSeriesTitle = styled.h3`
  font-size: 1.05em;
  margin: 0.5em 0 0.2em;
`;

/**
 * Sub-group of a series.
 */
export const StatusGroup = styled.details`
  margin: 0.2em 0;
`;

/**
 * Summary of a sub-group.
 */
export const StatusGroupSummary = styled.summary`
  cursor: pointer;
  font-weight: bold;
  font-size: 0.95em;
`;

/**
 * Label of a win / lose subsection inside a job group.
 */
export const StatusKindLabel = styled.span`
  display: block;
  margin: 0.4em 0 0.1em;
  font-size: 0.9em;
  font-weight: bold;
  color: ${helperTextColor};
`;

/**
 * A job group nested inside a team group (indented to show subordination).
 */
export const StatusJobGroup = styled.details`
  margin: 0.2em 0 0.2em 1.4em;
  padding-left: 0.8em;
  border-left: 1px solid ${lightBorderColor};
`;

/**
 * Indented content block directly under a team group (e.g. the win/lose
 * subsections of the "all" team).
 */
export const StatusIndent = styled.div`
  margin: 0.2em 0 0.2em 1.4em;
  padding-left: 0.8em;
  border-left: 1px solid ${lightBorderColor};
`;

/**
 * List of prize status rows.
 */
export const StatusList = styled.ol`
  margin: 0.2em 0;
  padding-left: 1.4em;
`;

/**
 * One prize status row.
 */
export const StatusRowItem = styled.li`
  margin: 0.15em 0;
  line-height: 1.6;

  ${phone`
    margin: 0.25em 0;
  `};
`;

/**
 * Displayed name of a prize.
 */
export const StatusPrizeName = styled.span`
  font-weight: bold;
`;

/**
 * Condition text of a prize.
 */
export const StatusCondition = styled.span`
  font-size: 0.85em;
  color: ${helperTextColor};
  margin-left: 0.5em;
`;

/**
 * Progress bar of a prize.
 */
export const StatusProgressBar = styled.span<{ percent: number }>`
  display: inline-block;
  width: 6em;
  height: 0.8em;
  margin-left: 0.5em;
  background-color: ${noColor};
  position: relative;

  &::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: ${({ percent }) => `${Math.max(0, Math.min(100, percent))}%`};
    background-color: ${yesColor};
  }
`;

/**
 * Text of current progress.
 */
export const StatusProgressText = styled.span`
  font-size: 0.85em;
  min-width: 4em;
`;

/**
 * Badge of achieved / not achieved.
 */
export const StatusAchievedBadge = styled.span<{ achieved: boolean }>`
  font-size: 0.85em;
  font-weight: bold;
  color: ${({ achieved }) => (achieved ? activeButtonColor : helperTextColor)};
`;
