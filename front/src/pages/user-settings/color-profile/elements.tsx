import styled from '../../../util/styled';
import { phone } from '../../../common/media';
import { borderColor } from '../../../common/forms/button';
import {
  ControlsWrapper,
  ControlsName,
} from '../../../common/forms/controls-wrapper';

/**
 * Wrapper of whole content.
 */
export const WholeWrapper = styled.div`
  display: flex;
  flex-flow: row nowrap;
  ${phone`
    flex-flow: column nowrap;
  `};
`;

export const MainTableWrapper = styled.div`
  flex: auto 0 1;
  padding: 0 20px;
  border-right: 1px solid ${borderColor};
  ${phone`
    order: 1;
  `};
`;
export const ProfileListWrapper = styled.div`
  flex: 300px 0 1;
  margin: 0 20px;
`;

/**
 * Table of all color settings.
 */
export const ColorsTable = styled.table`
  margin-right: auto;
  border-collapse: collapse;
  user-select: none;

  th,
  td {
    border: 1px solid ${borderColor};
  }
  th {
    vertical-align: middle;
  }
`;

/**
 * Sample text.
 */
export const SampleTextWrapper = styled.div`
  display: inline-block;
  vertical-align: middle;

  margin: 4px;
  padding: 4px;
`;

/**
 * Wrapper of profile.
 * @package
 */
export const ProfileWrapper = styled(ControlsWrapper)<{
  defaultProfile: boolean;
}>`
  background-color: ${({ defaultProfile }) =>
    defaultProfile ? '#f0f0f0' : 'transparent'};
`;

/**
 * Name of profile.
 * @package
 */
export const ProfileName = ControlsName;
