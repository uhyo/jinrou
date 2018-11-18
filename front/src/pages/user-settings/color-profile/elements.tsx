import styled, { withProps } from '../../../util/styled';
import { phone } from '../../../common/media';

/**
 * Color used for borders.
 */
const borderColor = '#dddddd';

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
 */
export const ProfileWrapper = withProps<{
  defaultProfile: boolean;
}>()(styled.div)`
  margin: 1em 0;
  border: 1px solid ${borderColor};
  padding: 8px;

  background-color: ${({ defaultProfile }) =>
    defaultProfile ? '#f0f0f0' : 'transparent'};
`;

/**
 * Name of profile.
 */
export const ProfileName = styled.div`
  margin: 0 0 0.2em 0;
  font-weight: bold;
`;

/**
 * Reusable button.
 */
export const Button = styled.button`
  display: inline-block;
  margin: 6px;
  background-color: white;
  border: 1px solid ${borderColor};
  border-radius: 3px;
  padding: 8px 10px;
`;

/**
 * Button with pretty background.
 */
export const ActiveButton = styled(Button)`
  background-color: #009900;
  color: white;
`;
