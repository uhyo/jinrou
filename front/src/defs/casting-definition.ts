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
     * Whether this casting allows exclusion of roles.
     */
    roleExclusion?: boolean;
    /**
     * Do not fill remaining players by Humans.
     */
    noFill?: boolean;
    /**
     * Whether to use category query.
     */
    category?: boolean;
    /**
     * Function to define this casting.
     */
    preset?: PresetFunction
    /**
     * Options suggested to this rule.
     */
    suggestedOptions?: Record<string, OptionSuggestion>;
    /**
     * Check whether this number of players is admissible.
     */
    suggestedPlayersNumber?: {
        min?: number;
        max?: number;
    };
}

/**
 * Preset jobs function.
 * Absent field of return value should be considered as 0.
 */
export type PresetFunction = (players: number)=> Record<string, number>;

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
