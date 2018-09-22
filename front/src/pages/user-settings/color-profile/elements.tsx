import styled, { withProps } from '../../../util/styled';

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
`;

export const MainTableWrapper = styled.div`
  flex: auto 0 1;
  margin-right: 20px;
`;
export const ProfileListWrapper = styled.div`
  flex: auto 0 0;

  border-left: 1px solid ${borderColor};
  padding-left: 20px;
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
  box-sizing: border-box;
  width: 200px;
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
