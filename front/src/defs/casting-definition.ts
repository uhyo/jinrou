/**
 * Definition of casting.
 */
export interface CastingDefinition {
    /**
     * ID of this casting.
     */
    id: string;
    /**
     * name of this casting.
     */
    name: string;
    /**
     * description of casting.
     */
    label: string;
    /**
     * Whether this casting allows user selection of roles.
     */
    roleSelect: boolean;
    /**
     * Function to define this casting.
     */
    preset?: (players: number)=> Record<string, number>;
    /**
     * Options suggested to this rule.
     */
    suggestedOptions?: Record<string, OptionSuggestion>;
}

/**
 * Suggestion of an option.
 */
export type OptionSuggestion = string | RangeOptionSuggestion;

/**
 * Suggestion of number option/
 */
export interface RangeOptionSuggestion {
    type: 'range';
    min?: number;
    max?: number;
}
