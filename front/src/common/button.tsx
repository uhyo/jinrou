import styled from 'styled-components';
import * as React from 'react';

export const WideButton = styled.button`
    appearance: none;
    width :-moz-available;
    width :-webkit-fill-available;
    width: stretch;

    border: none;
    padding: 0.5em;

    font-size: 1.1em;

    background-color: rgba(224, 224, 224, 0.75);

    :hover {
        background-color: rgba(224, 224, 224, 0.9);
    }
`;
