import styled from '../util/styled';
import { phone } from '../common/media';

/**
 * Area for whole app, which adds proper styles for phones.
 * By setting font size of form controls to 16, we can prevent
 * iOS's auto-zoom feature from working.
 */
export const AppStyling = styled.div`
  ${phone`
    input[type="button"],
    input[type="color"],
    input[type="date"],
    input[type="datetime"],
    input[type="datetime-local"],
    input[type="email"],
    input[type="month"],
    input[type="number"],
    input[type="password"],
    input[type="reset"],
    input[type="search"],
    input[type="submit"],
    input[type="tel"],
    input[type="text"],
    input[type="time"],
    input[type="url"],
    input[type="week"],
    select,
    textarea {
      font-size: 16px;
    }
`};
`;
