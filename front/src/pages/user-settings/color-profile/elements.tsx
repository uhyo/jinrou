import styled, { withProps } from '../../../util/styled';

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
    border: 1px solid #dddddd;
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
