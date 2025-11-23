<?php 

declare(strict_types=1);

namespace App\Dto;

/** 
 * Resultat paginé d'une recherche d'entreprise
 */ 
class SearchResult 
{
    /**
     * @param Entreprise[] $results
     */
    public function __construct(
        public readonly array $results,
        public readonly int $totalResults,
        public readonly int $page,
        public readonly int $perPage,
        public readonly string $totalPages
    )
    {
        
    }

    /** 
     * Permet à la classe de se créer lui même en objet en hydratant les bonnes données
     */ 
    public static function fromArray(array $data): self
    {
        $results = array_map(
            fn(array $item) => Entreprise::fromArray($item),
            $data['results'] ?? []
        );

        // Depuis PHP8 on peut utiliser cette syntaxe siret: ...
        return new self(
            results: $results,
            totalResults: $data['total_results'] ?? 0,
            page: $data['page'] ?? 1,
            perPage: $data['per_page'] ?? 10,
            totalPages: $data['total_pages'] ?? 0
        );
    }

    public function hasResults(): bool
    {
        return count($this->results) > 0;
    }

    public function getFirstResult(): ?Entreprise
    {
        return $this->results[0] ?? null;
    }
}