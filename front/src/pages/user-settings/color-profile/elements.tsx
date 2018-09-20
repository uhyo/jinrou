import styled, { withProps } from '../../../util/styled';

/**
 * Table of all color settings.
 */
export const ColorsTable = styled.table`
  border-collapse: collapse;

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
