<?php 

declare(strict_types=1);

namespace App\Dto;

/** 
 * Représente le siège d'une entreprise de l'API Recherche d'entreprise
 */ 
class Siege 
{
    public function __construct(
        public readonly string $siret,
        public readonly string $adresse,
        public readonly ?string $codePostal = null,
        public readonly ?string $commune = null,
        public readonly ?string $etatAdministratif = null,
    )
    {
        
    }

    /** 
     * Permet à la classe de se créer lui même en objet en hydratant les bonnes données
     */ 
    public static function fromArray(array $data): self
    {
        // Depuis PHP8 on peut utiliser cette syntaxe siret: ...
        return new self(
            siret: $data['siret'] ?? '',
            adresse: $data['adresse'] ?? '',
            codePostal: $data['code_postal'] ?? null,
            commune: $data['commune'] ?? null,
            etatAdministratif: $data['etat_administratif'] ?? null,
        );
    }

    public function isActif(): bool
    {
        return $this->etatAdministratif === 'A';
    }
}